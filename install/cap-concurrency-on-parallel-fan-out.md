### Cap Concurrency on Parallel Fan-Out

NEVER launch parallel work whose concurrency equals the input size. `Promise.all(items.map(...))`, `gather(*all_tasks)`, or a goroutine per element means production data decides your parallelism. Always run fan-out through an explicit concurrency limit.

- Use a bounded executor: a worker-pool/limit utility (`p-limit`, `p-map` with `{concurrency: N}` in Node), `asyncio.Semaphore` around each task in Python, a semaphore or worker-pool of N goroutines reading from a channel in Go, `errgroup.SetLimit(n)`.
- Pick the limit from the bottleneck, not vibes: respect the target's documented rate limit, your connection pool size, and per-host socket limits. Single digits to low tens is the usual answer for external APIs; defaulting to something like 10 beats defaulting to ∞.
- Make the limit a named constant or config value so load tests and incidents can tune it without a code hunt.
- Handle partial failure deliberately: use `Promise.allSettled` / collect per-item results rather than first-error-aborts-everything, and report which items failed so the batch can be partially retried.
- Compose with your other limits: each parallel call still needs a timeout, and retries inside fan-out must be jittered — N parallel naive retries is the storm with a head start.
- If items number in the hundreds of thousands, fan-out in the request path is the wrong tool entirely — enqueue the work for background workers instead.

**Red flags that you're about to violate this:**
- "Promise.all is the idiomatic way to parallelize."
- "There are only ever a few items in this list." (Enforced where?)
- "More concurrency means it finishes faster." (Until the rate limiter, pool, or kernel disagrees.)
- "Goroutines are cheap, spawn one per row."
- "The downstream service can handle it, it's internal."
- "I'll deal with failures by letting the whole batch throw."
