---
title: Release Locks Before You Await
slug: release-locks-before-you-await
category: concurrency
tags: [universal, concurrency, locks]
works_with: all
severity: critical
one_liner: "Stops locks held across awaits and I/O from strangling the whole service"
---

# Release Locks Before You Await

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from holding a lock across an `await` or a network call, turning a microsecond critical section into a multi-second global stall or a full deadlock.

**[Copy-paste ready version](../../install/release-locks-before-you-await.md)** — just the instruction block, no explanation.

## The Problem

A lock is supposed to protect a few lines of memory manipulation. The AI wraps the whole function body in it instead, including the `await fetch(...)` or the database call in the middle. Now every other task that needs that lock waits not for a memory write, but for someone else's network round trip. P99 latency of the slow endpoint becomes the floor latency of every endpoint that touches the lock. And if the awaited operation itself ever needs the same lock (directly, or through a callback, or through a re-entrant request to the same service), you don't get latency. You get a deadlock that no test has ever produced.

AI assistants do this because `lock { ...entire function... }` is the safest-looking shape in a single-threaded mental model: nothing inside can race, so wrapping more is "more correct." Every local test passes, because tests run one task at a time and the lock is never contended. The cost only appears when two real requests overlap, which is precisely the situation the test suite never creates.

The async variant is the nastiest: in single-threaded async runtimes (Node, Python asyncio), an `await` inside a critical section is an explicit invitation for every other task to run, including the ones the lock was supposed to exclude, while you still hold the mutex object they're queued on.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Release Locks Before You Await

NEVER hold a lock, mutex, or semaphore across an `await`, a network call, a disk read, or any operation whose duration you don't control. A critical section must contain only fast, local, in-memory work.

Locks held across I/O serialize the entire service behind the slowest caller, and deadlock outright when the awaited work re-enters the same lock.

- Structure code as: acquire → read/copy what you need → release → do the slow work → acquire → write the result. Two short critical sections, not one long one.
- Wrong: `async with lock: data = await fetch(url); cache[key] = data`. Right: read inputs under the lock, `await fetch` with no lock held, write the result under the lock (and re-validate before writing, since the world moved while you were away).
- Never call user-provided callbacks, emit events, or log to remote sinks while holding a lock. You can't see what they acquire.
- If the slow work genuinely must be exclusive (one refresh at a time), use a dedicated flag or single-flight pattern around the work, not the data lock across the I/O.
- In Java/C#/Go, the same rule applies to blocking I/O inside `synchronized`/`lock`/`mu.Lock()` regions: I/O does not belong inside.

**Red flags that you're about to violate this:**
- "Wrapping the whole function in the lock is simpler and definitely safe."
- "The fetch is fast, the lock won't be held long."
- "Releasing and re-acquiring is more code and more chances for bugs."
- "Nothing else uses this lock right now."
- "It's async, so the lock isn't really blocking anyone."

---

## Why It Works

1. **It gives the AI a concrete shape to emit** (acquire → copy → release → I/O → acquire → write), so "be careful with locks" becomes a pattern it can pattern-match against, not a vibe.
2. **It attacks the "more lock is safer" heuristic directly.** The default failure isn't forgetting the lock; it's over-applying it, and the rule names that as the bug.
3. **It forces the re-validation step** after re-acquiring, which is where the actual correctness lives once the critical section is split.
4. **Uncontended tests prove nothing about contention** — the rule substitutes a structural check the AI can apply without ever running two tasks.

## Origin

A token-refresh helper acquired the auth mutex, then awaited the identity provider over the network while holding it. Every request handler touched that mutex to read the current token. The day the identity provider had a 30-second brownout, one refresh call pinned the mutex and the entire API, hundreds of unrelated endpoints, queued behind one HTTP request. The service was "up," every health check passed, and nothing handled traffic for half a minute at a time, repeatedly, until someone read the stack dump and found four hundred tasks parked on one lock.
