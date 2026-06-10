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
