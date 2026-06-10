### Cap Unbounded Growth in Long-Lived State

NEVER add entries to a collection that outlives the request (module-level, global, singleton, long-lived class field) without a mechanism that removes them. In a long-running process, a collection with inserts and no evictions is a scheduled out-of-memory crash; only the date is unknown.

This covers every long-lived accumulator, not just caches: dedupe sets, history/audit arrays, per-session or per-user maps, retry queues, metric label sets, connection registries.

- For every insert into long-lived state, write down what removes the entry: TTL expiry, max-size with eviction, deletion on session end/disconnect, or periodic pruning. "Nothing" is not an answer; pick one and implement it in the same change.
- Keyed-by-unbounded-input is the danger sign: keys from user IDs, URLs, request IDs, or external events grow with traffic, not with code. A map keyed by a small fixed enum is fine; a map keyed by anything callers control is not.
- For dedupe and rate-limit state, bound the window: keep IDs for N minutes or keep the last N entries, not forever. Exact-forever dedupe of an infinite stream requires infinite memory by definition.
- Tie per-entity state to the entity's end-of-life: delete the session entry on logout/expiry, drop the connection record on close, including the error paths.
- Verify under sustained load, not a single pass: run the realistic flow for thousands of iterations and confirm collection sizes and heap plateau instead of climbing. A linear memory-vs-time chart is a failed test.

**Red flags that you're about to violate this:**
- "Each entry is only a few bytes."
- "The process gets redeployed often enough."
- "I'll add eviction once it becomes a problem."
- "We need to remember every ID or dedupe might miss one."
- "Memory is cheap."
- "It's not a cache, so the cache-bounding rule doesn't apply."
