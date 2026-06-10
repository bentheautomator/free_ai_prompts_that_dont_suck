---
title: Never Store Request State in Globals
slug: never-store-request-state-in-globals
category: backend
tags: [universal, backend]
works_with: all
severity: critical
one_liner: "Stops one user's request data from leaking into another user's response"
---

# Never Store Request State in Globals

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents request-scoped data stashed in globals or module-level variables from bleeding across concurrent requests and users.

**[Copy-paste ready version](../../install/never-store-request-state-in-globals.md)** — just the instruction block, no explanation.

## The Problem

A function deep in the call stack needs the current user. The clean fix is threading it through parameters or using the framework's request context. The fast fix — the one AI assistants reach for when the parameter plumbing gets tedious — is `current_user = user` at module level, set in middleware, read wherever needed. It works flawlessly in dev, because dev is one person sending one request at a time. The global always contains *your* user, because there is no one else.

Production servers handle requests concurrently. In threaded and async runtimes, request B's middleware overwrites the global while request A's handler is still mid-flight. Request A now reads request B's user. The symptoms are the stuff of incident legend: a customer opens their account page and sees someone else's name, orders, and saved cards. It's intermittent, load-dependent, and unreproducible locally — the worst class of bug, and also frequently a reportable data breach.

The same trap wears other costumes: a mutable default argument in Python accumulating across calls, a singleton service object with a `this.currentRequest` field, a module-level `dict` used as a per-request scratchpad, locale or tenant ID stored statically. Anything written per-request and stored process-wide is shared by every request in flight.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Store Request State in Globals

NEVER store request-scoped data — current user, tenant, locale, auth token, trace ID, the request object itself — in a global, module-level, static, or singleton-instance variable. The process is shared by all concurrent requests; anything stored process-wide will be read by the wrong request under load, which means one user seeing another user's data.

- Pass request state explicitly through function parameters, or carry it in the mechanism built for this: `contextvars` (Python async), `AsyncLocalStorage` (Node), `context.Context` (Go), request-scoped DI beans (Java/Spring), `flask.g`/`request` (which are context-local, not true globals).
- Never use thread-locals in async runtimes: one thread interleaves many requests, so thread-local is just a slower global.
- Keep fields like `currentUser`, `requestId`, or `tenantId` off singleton services. Singletons may hold configuration and connections (immutable or internally synchronized) — never per-request values.
- In Python, never use mutable default arguments (`def f(items=[])`) or module-level mutable containers as scratch space; they persist across requests for the life of the worker.
- Treat caches keyed without a tenant/user component as the same bug: a "current permissions" cache with a global key serves the first caller's permissions to everyone.
- If a global must be mutated at request time, stop — that is the design error, not an implementation detail to synchronize.

**Red flags that you're about to violate this:**
- "I'll store the user in a module variable so I don't have to pass it everywhere."
- "Setting it in middleware and reading it later is cleaner."
- "Each request gets its own thread, so a static field is fine." (Not in async. Not with pooled threads.)
- "It's just a temporary scratch variable."
- "This service is a singleton, so I'll put the request on it."
- "We've never seen wrong data in dev or staging." (One user at a time never collides.)

---

## Why It Works

1. **It names the concurrency model the assistant isn't simulating.** The bug requires two interleaved requests; dev has one. Stating "the process is shared by all in-flight requests" injects the missing fact at write time.
2. **It blocks the thread-local trap.** The assistant's first "fix" for a global is a thread-local, which still fails in async runtimes — calling that out prevents trading the bug for its harder-to-see twin.
3. **It legitimizes the right amount of plumbing.** Assistants choose globals to avoid threading a parameter through five layers; naming `contextvars`/`AsyncLocalStorage`/`context.Context` gives them a sanctioned way to avoid the plumbing without sharing state.
4. **It frames the stakes as a breach, not a bug.** Cross-user data exposure carries disclosure obligations; that severity justifies refactoring instead of patching.

## Origin

An e-commerce backend cached "the current customer's discount tier" in a module-level variable, set by auth middleware. Under a flash-sale load spike, interleaved requests crossed: some shoppers got other customers' VIP pricing, and a few saw another account's email on the checkout page. It had run for months without complaint — traffic had simply never been concurrent enough to collide. The incident review reclassified it from bug to privacy event, which changed everyone's afternoon.
