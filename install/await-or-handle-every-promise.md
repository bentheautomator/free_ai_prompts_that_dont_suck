### Await or Handle Every Promise

Every promise (and coroutine/task) must be awaited, returned, or given an explicit rejection handler. NEVER leave an async call floating — its failure has nowhere to go.

- Default to `await`. If you genuinely want fire-and-forget, you must still handle rejection: `void doWork().catch(err => logger.error("background work failed", err));` — and the `void` plus `.catch` signals the choice was deliberate
- Never use `forEach(async ...)`: forEach discards the promises, so nothing is awaited and every rejection is orphaned. Use `for...of` with `await`, or `await Promise.all(items.map(...))`
- `Promise.all` rejects on first failure and abandons the rest; when each item's outcome matters, use `Promise.allSettled` and *inspect the results* — calling allSettled and ignoring the rejected entries is the same swallowing with extra steps
- Python: every coroutine call gets `await`; every `asyncio.create_task()` result gets stored and eventually awaited (or given a done-callback that logs exceptions) — a bare `create_task` whose reference is dropped can be garbage-collected mid-flight, exception unreported
- When making a function async during a refactor, update every call site in the same change; search for calls to it that lack `await`
- Enable the linter that catches this (`@typescript-eslint/no-floating-promises`, `no-misused-promises`) when touching project config is in scope; it converts this whole class from runtime mystery to compile-time error

**Red flags that you're about to violate this:**
- "This doesn't need to block, so I'll skip the await..."
- "Logging/analytics can be fire-and-forget..."
- "forEach with an async callback handles each item..."
- "If the background task fails, it's not critical..."
- "I made the function async; the callers should still work..."
