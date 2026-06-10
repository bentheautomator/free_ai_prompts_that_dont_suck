### Don't Memoize Cheap or One-Shot Work

NEVER add memoization (`lru_cache`, `useMemo`, `computed`, hand-rolled result caches) unless all three are true: the computation is expensive, the same inputs actually recur, and the function is pure. Memoization that fails any of the three is overhead at best and a leak or stale-data bug at worst.

- Expensive: the work must cost meaningfully more than a hash-plus-dict-lookup. Arithmetic, string formatting, simple conditionals, and property access never qualify.
- Recurring: estimate the hit rate before adding the cache. If keys are unique per call (request IDs, timestamps, user-typed strings), the hit rate is zero and the cache is a pure cost — possibly an unbounded one.
- Pure: the function must depend only on its arguments. Memoizing anything that reads the clock, randomness, a database, config, or mutable state serves a frozen first answer forever. That's a correctness bug, not an optimization.
- Know the trap variants: `lru_cache` on instance methods pins `self` (and everything it references) in the cache; mutable arguments make keys unreliable; module-level caches in long-lived processes need the same bounding as any cache.
- In UI frameworks, don't reflexively wrap every value in `useMemo`/`useCallback`; the dependency tracking itself has a cost and most values are cheaper to recompute. Reserve it for measured re-render or recompute problems.
- Verify by measuring with and without, on realistic call patterns, and by logging the hit rate. A memo with a sub-50% hit rate on cheap work should be deleted.

**Red flags that you're about to violate this:**
- "Caching this can't hurt."
- "I'll memoize it while I'm here, as a best practice."
- "This might be called with the same arguments sometimes."
- "useMemo on everything keeps renders fast."
- "It reads config, but config basically never changes."
- "The decorator is only one line."
