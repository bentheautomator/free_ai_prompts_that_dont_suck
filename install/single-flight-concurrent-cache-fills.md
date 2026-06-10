### Single-Flight Concurrent Cache Fills

A cache fill MUST be deduplicated per key: when callers miss concurrently, exactly one computes the value and the rest await that same computation. Check-compute-store with no in-flight tracking sends every concurrent miss to the backend at once.

A cache without single-flight protects the backend only between expirations, and attacks it at every one.

- In-process: keep a map of in-flight promises/futures per key. On miss, atomically check it — found means await it; absent means insert your promise *before* starting the fetch (insert-then-fetch, or the second caller slips through). Remove the entry when the fill completes.
- Clean up on failure: remove the in-flight entry and decide whether waiters get the error or a retry — but never leave a rejected promise as the permanent answer for the key, and never let a failed fill keep new callers queued behind a corpse.
- Use the built-in where one exists: Go's `singleflight` package, caching libraries with `getOrCompute`/loader semantics that document fill deduplication. Don't hand-roll what the platform provides.
- Cross-instance stampedes (many servers, one Redis, one hot key) need more than in-process tracking: a short-TTL fill lock, probabilistic early refresh, or serving the stale value while one worker revalidates (stale-while-revalidate). Pick one deliberately for genuinely hot keys.
- Expiry policy is part of the fix: refreshing a hot key *before* expiry (background refresh) means concurrent misses never happen on it at all.
- Don't confuse this with lazy init: singletons fill once per process; caches fill per key, repeatedly, under TTL — the dedup must be keyed and must reset after each fill.

**Red flags that you're about to violate this:**
- "Check cache, on miss compute and store — that's just what a cache is."
- "Duplicate fills are wasteful but harmless; same value either way." (Two hundred copies of the same expensive query is the outage.)
- "The TTL is long, misses are rare." (Rare and synchronized: every caller misses at the same moment.)
- "Our load tests passed." (Did one warm the cache first?)
- "I'll lock the whole cache during fills." (Now every key waits on one key's slow fetch.)
