---
title: Never Share Mutable State Across Requests
slug: never-share-mutable-state-across-requests
category: concurrency
tags: [universal, concurrency, state]
works_with: all
severity: critical
one_liner: "Stops module-level mutable state from leaking data between concurrent requests"
---

# Never Share Mutable State Across Requests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from stashing per-request data in module-level variables, singletons, or reused objects, where concurrent requests overwrite each other and users see each other's data.

**[Copy-paste ready version](../../install/never-share-mutable-state-across-requests.md)** — just the instruction block, no explanation.

## The Problem

The AI needs to pass the current user from middleware to a helper three layers down. Threading a parameter through is tedious, so it writes `currentUser = user` at module scope and reads it in the helper. With one request at a time, this is flawless. With two concurrent requests, request B's middleware overwrites `currentUser` while request A's handler is still mid-await, and A's invoice gets B's name on it. The same trap wears many costumes: a dict on a singleton service, a reused class-level buffer, a `lastError` field, mutable default arguments in Python, a module-scope array used as a scratchpad.

Assistants reach for this because module state is the path of least resistance for "make X available over there," and because nothing about `currentUser = user` looks dangerous. Every test passes: test frameworks run requests one at a time, so the overwrite window never opens. The production failure is rare, unreproducible, and horrifying, because it's not a crash. It's user A seeing user B's account. That's an incident report and sometimes a regulator.

Server frameworks make it worse by encouraging long-lived objects: a handler class instantiated once, a service registered as a singleton. Any mutable field on those objects is shared by every in-flight request, whether the author meant it or not.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Share Mutable State Across Requests

NEVER store per-request or per-task data in module-level variables, singleton fields, or any object that outlives one request. Everything request-scoped travels with the request.

State on a long-lived object is shared by every concurrent request; the first overlap mixes one user's data into another's response.

- Pass request-scoped data as parameters, on the request/context object, or via the runtime's context mechanism (`contextvars` in Python, `AsyncLocalStorage` in Node, `context.Context` values in Go). Never via assignment to anything global.
- Wrong: `this.currentUser = user` on a singleton service, then reading it later in the same "request." Between those two lines, other requests ran.
- Audit any class registered as a singleton or created at module import: every mutable field on it must be either immutable config, a thread-safe structure used as one, or deleted.
- No reusable scratch buffers, `lastResult` fields, or accumulating lists on shared objects. Allocate per call; the allocator is cheaper than the incident.
- Python: never use mutable default arguments (`def f(x, acc=[])`) — the default is one shared object across all calls.
- Caches are the one legitimate shared mutable structure; they must be keyed so no entry is request-specific-but-unkeyed, and writes must be safe under concurrency.

**Red flags that you're about to violate this:**
- "Threading this parameter through five functions is ugly; a module variable is cleaner."
- "This service is a singleton anyway, I'll just put the field on it."
- "Requests are fast; the variable won't be overwritten mid-flight."
- "It worked in every test." (Tests run requests one at a time.)
- "I'll set it at the start and clear it at the end of the request."

---

## Why It Works

1. **It names the actual lifetime mismatch** — request-scoped data on a process-scoped object — which is a check the AI can run on any field it's about to add: "what outlives what?"
2. **It supplies the legitimate channels** (parameters, context objects, contextvars/AsyncLocalStorage), so the rule doesn't just forbid the easy path, it routes to an equally concrete one.
3. **"Every await is a door"**: framing the gap between set and read as a place other requests run makes the overwrite window visible in code the AI is writing.
4. **Single-request tests structurally cannot catch this,** so the rule replaces test-passing confidence with a lifetime argument made at write time.

## Origin

A PDF-statement service stored the active customer's account object on the renderer singleton "to avoid changing twelve method signatures." Under concurrent load, roughly one statement in a few thousand rendered with a different customer's transactions in it. It took months to discover because the PDFs were valid, well-formed, and mailed out. The fix was the boring one nobody wanted: the parameter got threaded through all twelve signatures, and the singleton's only remaining field was immutable config.
