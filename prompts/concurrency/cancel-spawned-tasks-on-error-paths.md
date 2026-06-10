---
title: Cancel Spawned Tasks on Error Paths
slug: cancel-spawned-tasks-on-error-paths
category: concurrency
tags: [universal, concurrency, async]
works_with: all
severity: high
one_liner: "Stops error paths from orphaning spawned tasks that keep running headless"
---

# Cancel Spawned Tasks on Error Paths

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing code that spawns concurrent tasks and then, when one fails or the function exits early, abandons the rest to run headless with no owner, no consumer, and no cancellation.

**[Copy-paste ready version](../../install/cancel-spawned-tasks-on-error-paths.md)** — just the instruction block, no explanation.

## The Problem

The AI spawns three workers, awaits them, and handles errors with a `try/catch` around the await. Looks complete. But trace the early exit: validation fails after two tasks are spawned, the function throws — and the two tasks keep running. Or `Promise.all` rejects on the first failure and the function returns, while the other promises *continue executing* (rejection means "stop waiting," not "stop working"); if one of them later rejects too, it's an unhandled rejection from a function that already returned. In Go, the goroutine reading from a channel nobody will ever drain blocks forever, leaking a stack and whatever it holds. The orphans write to databases on behalf of a request that already failed, hold connections from a pool that's now short, and produce side effects with no surviving context to explain them.

This happens because the AI's mental model ends at the function boundary: when the function exits, its work is "done." Spawned tasks break that model — they outlive the scope that created them unless something explicitly ties their lifetime to it. Tests pass because happy paths join everything, and error-path tests assert on the thrown error, not on what the abandoned tasks did three hundred milliseconds later.

Structured concurrency is the name for the fix: a scope's child tasks end when the scope ends, by completion or by cancellation, with no third option called "wandering off."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Cancel Spawned Tasks on Error Paths

Every task you spawn needs an owner, and every exit path — success, failure, early return, timeout — must either join or cancel it. NEVER let a function exit while tasks it spawned keep running unsupervised.

A rejected `gather` or thrown error stops the *waiting*, not the *work*; the survivors run on with no consumer for their results or errors.

- Use structured-concurrency tools where they exist: Python `asyncio.TaskGroup` (cancels siblings on failure, joins on exit), Go `errgroup.WithContext` (one failure cancels the shared context), Kotlin `coroutineScope`. Prefer these over hand-managed task lists.
- With raw `Promise.all`: on rejection the other promises keep executing. If they must stop, pass an `AbortSignal` into the work and abort in the catch; if they can't be stopped, at least attach a handler so late rejections don't become unhandled.
- Keep handles to everything you spawn. A task you can't reference is a task you can't cancel, await, or even observe failing — fire-and-track, never fire-and-forget.
- In try/finally terms: spawn inside `try`, and in `finally` cancel-and-await anything not yet joined. Cancellation without awaiting the cancelled task skips its cleanup.
- Cancellation must propagate: long-running spawned work should check its signal/context at await points and loop iterations, or "cancelled" is a flag nobody reads.
- On timeouts, the same rule: abandoning a timed-out task means it's still running. Cancel it, then handle the timeout.

**Red flags that you're about to violate this:**
- "If something throws, the whole operation just ends." (The spawned parts don't.)
- "The other tasks are harmless; let them finish on their own."
- "I don't need the handle; I'm not going to await it."
- "Promise.all handles the coordination for me."
- "Adding cancellation plumbing doubles the size of this function."

---

## Why It Works

1. **"Every spawn has an owner" turns leak-hunting into a local syntactic check:** at each spawn site, point to the join-or-cancel on every exit path, or the code is wrong.
2. **It corrects the precise false belief** — that `gather`/`Promise.all` rejection stops the work — which is the single misunderstanding behind most orphaned tasks.
3. **Structured-concurrency primitives make the right thing the default shape,** so lifetime management comes from the construct rather than from discipline on every error path.
4. **Cancel-then-await preserves cleanup,** closing the secondary leak where cancelled tasks die without releasing what they hold.

## Origin

An import endpoint spawned a parser task and an uploader task, then validated the file header — and threw on bad input, after the spawns. The orphaned uploader streamed the rejected file to storage anyway; the orphaned parser held a pool connection until it finished. A user with a malformed export retried in a loop, each attempt leaking one connection for several minutes, and the pool starved during business hours. The error logs showed only clean validation failures: the actual damage was being done by tasks whose owner had already returned a 400 and moved on.
