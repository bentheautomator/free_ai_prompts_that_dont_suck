### Never Blind-Retry Non-Idempotent Operations

Before adding retries to any operation, answer: if this executed twice, would the second execution be harmless? If not, you MUST NOT retry it until you've made it safe — a timeout may mean the first attempt actually succeeded.

A timeout is not "it didn't happen." It's "I don't know what happened." Retrying on top of an invisible success is how duplicates are born.

- Classify before wrapping: reads and idempotent writes (PUT to a fixed state, DELETE by id, upsert-by-key) may retry freely; creates, charges, sends, increments, and appends may not — by default
- To make a write retryable, give it an idempotency key: pass the provider's idempotency header (most payment and messaging APIs support one), or use a client-generated unique key with a uniqueness constraint so replays collide instead of duplicating
- Without an idempotency mechanism, a timed-out non-idempotent call must not be blindly re-sent: surface the ambiguous outcome to the caller, or query the resource first ("did order with this reference get created?") before re-attempting
- Distinguish failure classes: "connection refused before sending" is safe to retry even for writes (the request never arrived); "timeout awaiting response" is the dangerous ambiguity
- Never put a generic retry decorator/interceptor on a client that performs writes without auditing every write endpoint it covers
- Apply the same test to queue redelivery and cron re-runs: anything that may execute twice needs the same idempotency design, not just HTTP calls

**Red flags that you're about to violate this:**
- "I'll wrap this API call in the standard retry helper..."
- "Timeout means it failed, so retrying is safe..."
- "Duplicates are an edge case we can clean up later..."
- "The payment provider probably dedupes on their side..."
- "Three retries on the order endpoint will fix the flakiness..."
