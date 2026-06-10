### Dedupe Webhook Deliveries by Event ID

ALWAYS treat webhook delivery as at-least-once and deduplicate by the provider's event ID before running side effects. Every serious webhook provider redelivers on timeout, error, or internal retry; a handler that acts once per delivery will act twice per event.

- Extract the provider's unique event ID (e.g. `event.id`, a delivery GUID header) and record it in durable storage with a unique constraint as part of processing. If the insert conflicts, the event was already handled: return 200 and do nothing.
- Make the dedup check atomic with the work, or at minimum insert-first: `INSERT ... ON CONFLICT DO NOTHING` and only proceed if the row was inserted. A read-then-act check loses to two deliveries arriving concurrently, which providers genuinely do.
- Return success for duplicates. Returning an error tells the provider the delivery failed and earns you another redelivery of the event you just declined.
- Dedup storage must be shared and durable: a database table or shared store, never an in-process `Set` (wiped on restart, invisible to other replicas).
- If the provider sends no event ID, derive a deterministic one from stable payload fields and document the choice.
- Keep processed-ID rows at least as long as the provider's maximum retry window (check the docs; days, not minutes), then prune by timestamp.

**Red flags that you're about to violate this:**
- "The provider sends each event once, that's the whole point of webhooks."
- "Duplicates would only happen if we error, and we won't error."
- "I'll keep a set of seen IDs in memory."
- "Checking for an existing order status first is enough deduplication."
- "Returning 409 on duplicates seems more semantically correct."
- "Dedup is something we can add when it becomes a problem."
