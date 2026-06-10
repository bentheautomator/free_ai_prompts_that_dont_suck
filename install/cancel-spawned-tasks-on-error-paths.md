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
