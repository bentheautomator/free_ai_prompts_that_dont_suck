---
title: Make Lazy Initialization Thread-Safe
slug: make-lazy-initialization-thread-safe
category: concurrency
tags: [universal, concurrency, state]
works_with: all
severity: high
one_liner: "Stops if-null-then-create singletons that initialize twice under load"
---

# Make Lazy Initialization Thread-Safe

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing `if (!instance) instance = create()` lazy initialization that two concurrent callers can run twice, leaking duplicate clients and split state.

**[Copy-paste ready version](../../install/make-lazy-initialization-thread-safe.md)** — just the instruction block, no explanation.

## The Problem

`if (instance === null) { instance = await createClient(); } return instance;` is the lazy singleton every AI writes on the first try. Under concurrency it has a hole exactly where it matters: two callers both see `null`, both call `createClient()`, and now there are two clients. Sometimes that's a leaked connection pool. Sometimes it's two consumers competing for the same messages, two schedulers running the same cron, or two in-memory caches that disagree forever after. The `await` inside the initializer widens the window from nanoseconds to an entire network round trip — in async code, double-init isn't a freak event, it's the common case on a cold start with concurrent traffic.

The AI writes it this way because the pattern is *the* textbook lazy init, and in a single-caller world it's correct. The bug only exists during the first moments of process life under simultaneous demand: precisely a cold deploy taking production traffic, and precisely never in a test that calls the getter once.

Worse, the broken version usually self-heals: the second assignment wins, the first client is orphaned but functional, and the only symptoms are a slow connection leak and occasional impossible behavior ("the config says X, the service does Y") from callers holding the loser.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Lazy Initialization Thread-Safe

NEVER write bare `if (not initialized) → initialize` for shared resources. Concurrent first callers will all pass the check; the initializer must run exactly once no matter how many arrive at once.

The window is widest exactly when it matters: at cold start, when the initializer is slow and the callers are many.

- Async runtimes: memoize the *promise*, not the result. `if (!clientPromise) clientPromise = createClient(); return clientPromise;` — the assignment happens synchronously before any await, so late arrivals share the same in-flight initialization. (Python: store the Task; guard creation with a lock if there are real threads.)
- Threaded runtimes: use the platform's once-primitive — Go `sync.Once`, Python `threading.Lock` around check-and-create, Java holder idiom or a static initializer, C++ function-local static, Rust `OnceLock`/`lazy_static`. Do not hand-roll double-checked locking; most hand-rolled versions are wrong about memory visibility.
- Simplest fix when startup cost allows: initialize eagerly at startup and delete the laziness. A resource always needed isn't lazy, it's just late.
- If the memoized initialization can *fail*, decide what happens: clear the stored promise on rejection so the next caller retries, or every future caller inherits the cached failure forever.
- The same rule covers any "create if missing" on shared maps: use the atomic get-or-create your structure offers (`computeIfAbsent`, `setdefault` under lock), not check-then-insert.

**Red flags that you're about to violate this:**
- "Initialization happens once at startup, there's no race."
- "The check-then-create window is a few nanoseconds." (There's an `await` in it.)
- "Worst case it initializes twice; the second one wins, no harm."
- "Double-checked locking, I remember roughly how it goes."
- "It's only a cache/client/logger; duplicates are harmless."

---

## Why It Works

1. **Memoizing the promise is the precise mechanical fix for the async case** — the race lives between the null-check and the assignment, and moving the assignment before the first await closes it by construction.
2. **It routes threaded code to vetted once-primitives,** because the failure mode of hand-rolled lazy init isn't sloppiness, it's memory-model subtleties no review will catch.
3. **It forces the failure-caching decision,** the second-order bug hiding inside the correct pattern: a memoized rejection is an outage with a cache.
4. **"Make it eager" removes the entire bug class** in the majority of cases where laziness was never a requirement, just a habit.

## Origin

A service lazily created its message-queue consumer on first use. A cold deploy under load ran the initializer three times; three consumers in one process split the partition's messages, and a dedupe layer downstream hid two-thirds of the damage until someone noticed processing throughput was mysteriously exactly 3x the message volume. The orphaned consumers had no handle anywhere — they couldn't even be shut down without killing the process. One line, memoize-the-promise, ended it.
