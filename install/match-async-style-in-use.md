### Match the Async Style in Use

ALWAYS write asynchronous code in the same idiom the surrounding code uses. Concurrency style is not a preference slot — the file already chose between async/await, promise chains, callbacks, threads, or an event loop, and your addition joins that choice.

The seams between mixed idioms are where errors get lost: unreturned promises inside async functions, rejections that no callback ever sees, coroutines that are never awaited and never run.

**Before writing async code:**
- Look at how the nearest similar code handles it: async/await vs `.then()` vs callbacks (JS); asyncio vs threads vs sync (Python); goroutines/channels vs sync (Go); and match it — including the error idiom that goes with it (`try/catch` around `await`, `.catch()` on chains, error-first callbacks)
- Don't convert existing code's style to enable yours — write yours to fit theirs; if bridging is unavoidable (a callback API in promise-land), use the codebase's established bridge (`promisify`, existing wrapper utilities), not a hand-rolled adapter
- In an async/await file, never bolt `.then()` onto an awaited expression or leave a promise floating unawaited — every promise is awaited, returned, or explicitly handled
- In Python, never call a coroutine without awaiting it, and never start a new event loop (`asyncio.run`) inside code that may already be in one — find how the codebase enters async and use that path
- Respect the codebase's concurrency primitives: if it has a task queue, a worker pool, or a scheduler for background work, use it rather than spawning ad-hoc threads/tasks

**Red flags that you're about to violate this:**
- ".then() reads more cleanly for this short chain..."
- "I'll fire this off without awaiting; we don't need the result..."
- "A quick background thread is simpler than their task queue..."
- "I'll make this one function async; callers can adapt..."
- "Mixing styles here is fine, JavaScript supports both..."
- Writing async code without having looked at how the file's existing async code handles errors
