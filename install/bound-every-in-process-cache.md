### Bound Every In-Process Cache

NEVER create an in-memory cache, memoization map, or lookup table that grows without a size bound in a long-lived process. An unbounded cache is a memory leak that hasn't finished yet.

- Every cache needs an eviction policy: an LRU with a max entry count, a TTL-based store, or a size-aware library (`lru_cache(maxsize=N)`, `caffeine`, `lru-cache` npm package). A bare `Map`/`dict`/`HashMap` used as a cache at module or singleton scope is wrong by default.
- `@functools.lru_cache(maxsize=None)` and `@cache` are unbounded — use an explicit `maxsize`. If you copy a memoization pattern from anywhere, check what bounds it.
- Before choosing a bound, state the key cardinality: who controls the keys and how many distinct values are possible? If the key derives from user input (URLs, query strings, arbitrary IDs, payload hashes), cardinality is effectively infinite and a bound plus TTL is mandatory.
- Caches keyed by request-scoped data must be request-scoped objects, not process-level ones — let them be garbage collected with the request.
- Memoizing on unbounded-cardinality keys "for speed" with a process-level dict counts as this failure even when you don't call it a cache.
- State the chosen bound and the estimated worst-case memory (entries × approximate entry size) in a comment at the cache site.

**Red flags that you're about to violate this:**
- "There will only ever be a handful of keys."
- "maxsize=None keeps every result, which maximizes the hit rate."
- "Eviction logic is overkill for this simple helper."
- "Memory is cheap; this map stays small in practice."
- "It's just memoization, not really a cache."
