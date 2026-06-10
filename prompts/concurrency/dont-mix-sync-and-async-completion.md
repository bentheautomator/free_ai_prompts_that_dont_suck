---
title: Don't Mix Sync and Async Completion
slug: dont-mix-sync-and-async-completion
category: concurrency
tags: [universal, concurrency, async]
works_with: all
severity: high
one_liner: "Stops functions that complete synchronously sometimes and async other times"
---

# Don't Mix Sync and Async Completion

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing "async" functions that sometimes finish or throw synchronously, so callers face two different execution orders depending on data.

**[Copy-paste ready version](../../install/dont-mix-sync-and-async-completion.md)** — just the instruction block, no explanation.

## The Problem

The AI writes a function that takes a callback and, on a cache hit, calls it immediately — synchronously, before returning. On a miss, it calls it after the fetch completes. Same function, two different universes: in one, the callback runs *before* the line after the call; in the other, *after*. Callers that set up state on the next line ("call `subscribe()`, then initialize the handler it will invoke") work on cache misses and explode on hits, or vice versa. This is the classic "released Zalgo" bug, and it produces the most disorienting failures in async code: order-dependent crashes that flip with cache temperature.

The promise-flavored variant: a function declared to return a promise but written to `throw` synchronously on bad input. `validate(x).catch(handle)` catches the async failures; the sync throw bypasses `.catch` entirely and detonates at the call site. And in Python, a coroutine that does blocking work or raises before its first `await` runs that code at a different time than the caller scheduled it for. Every one of these is a function whose *completion semantics* depend on its inputs.

AI assistants produce this because the sync shortcut is locally optimal — "I already have the value, why defer?" — and because nothing in the type signature distinguishes always-async from sometimes-async. Tests pass: each test exercises one path, and each path is individually correct. The bug is the *difference* between them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Mix Sync and Async Completion

A function that is ever asynchronous must be ALWAYS asynchronous: same completion timing, same error channel, on every path including cache hits and input validation.

Sometimes-sync functions give callers two execution orders for one call site; code that works on the slow path breaks on the fast path, or the reverse.

- Callback APIs: never invoke the callback synchronously on any path. Defer the fast path: `process.nextTick(() => cb(cached))` / `queueMicrotask` / `setImmediate`, so hit and miss have identical ordering.
- Promise-returning functions: deliver *all* failures through the promise. Wrong: `function f(x) { if (!valid(x)) throw Err; return fetch(x); }` — the throw skips every `.catch`. Make the function `async` (sync throws become rejections automatically) or return `Promise.reject(Err)`.
- Don't do heavy or blocking work before the first await in an async function; the caller scheduled a task, not an inline call. Yield first or move the work inside.
- Cached-value fast paths still return a promise: `return Promise.resolve(cached)`, never the raw value from a function that returns promises elsewhere (and never a raw value from one branch and a promise from another).
- Events: never emit synchronously from inside the constructor/subscribe call, before the caller has had a chance to attach listeners.
- One error channel per function. Pick sync or async; mixing means callers need try/catch *and* `.catch` to be safe, and nobody writes both.

**Red flags that you're about to violate this:**
- "I already have the cached value, deferring it is wasted latency."
- "Throwing early on bad input is fail-fast, that's good practice." (In a promise API it's a second error channel.)
- "Callers should handle both sync and async errors anyway."
- "Both paths are tested and both pass."
- "It returns the value directly on this branch, which is simpler."

---

## Why It Works

1. **"Always async" is checkable per-branch:** for each return/throw/callback-invocation, ask "does this complete synchronously?" — a local question with a yes/no answer, unlike "is this confusing."
2. **It names the exact mechanism of the damage** — two execution orders for one call site — so the AI understands why the microtask deferral isn't pedantry but the actual fix.
3. **The one-error-channel rule collapses the dual-handling burden** that otherwise gets silently half-implemented at every call site.
4. **It explains why per-path tests are blind here:** each path is correct alone; the bug lives in their disagreement, which only a caller relying on ordering can observe.

## Origin

A config loader called its ready-callback synchronously when config was already cached, asynchronously on first load. Service A initialized its handlers after calling `onReady`, which worked all through development (always a cold load) and failed on the first warm restart in production, where the callback fired into handlers that didn't exist yet. The crash happened only on restarts following a crash, which made the system effectively unable to recover without a full cold deploy, at 2 a.m., twice.
