### Make Retried Service Handlers Idempotent

NEVER write a handler that performs a non-idempotent mutation (charge, send, create, increment) without a mechanism to detect and absorb duplicate requests. Networks retry. Clients retry. Load balancers retry. Assume every mutating request will arrive at least twice.

- Accept an idempotency key (header or body field) on every mutating endpoint that creates side effects. If the caller is internal, derive one deterministically (e.g. `order_id + action`).
- Persist the key in the same atomic operation as the mutation — a unique constraint on the key, not a read-then-write check. `SELECT then INSERT` has a race window; `INSERT ... ON CONFLICT` does not.
- On a duplicate key, return the stored result of the first execution with the same status code — not an error. The retrying client should be unable to tell it was a replay.
- Pass the idempotency key through to downstream providers that support it (payment APIs, email APIs) so the protection extends past your own database.
- Don't fake idempotency with "check if a similar record exists in the last 5 minutes" heuristics. Time windows are not identity.
- Naturally idempotent operations (set status to X, PUT full resource) don't need keys — but verify they actually are, including any side effects they trigger.

**Red flags that you're about to violate this:**
- "The client will only call this once."
- "The frontend disables the button after submit, so duplicates can't happen."
- "I'll check if the record exists first, then insert."
- "This is an internal endpoint, nothing retries internal calls."
- "Adding idempotency keys is over-engineering for this feature."
- "The payment provider probably handles duplicates on their side."
