### Treat Every Queue as At-Least-Once Delivery

ALWAYS write queue and stream consumers assuming every message can be delivered two or more times, including concurrently to different workers. No broker setting exempts you: crash-before-ack, visibility-timeout expiry, and rebalances all produce duplicates, so duplicate-safety lives in the consumer.

- Give every message a stable unique ID at the producer (entity ID + operation, or a UUID minted once). Random IDs minted at consume time defeat deduplication by definition.
- Make the handler idempotent around that ID: record processed IDs in a store with a uniqueness guarantee (unique index, `INSERT ... ON CONFLICT DO NOTHING`, `SETNX`) and check-or-claim *atomically* before executing side effects. A read-then-write check has a race window exactly when two workers hold the same message.
- Where possible, make the operation naturally idempotent instead of tracking IDs: `SET status = 'shipped'` survives duplicates; `counter = counter + 1` does not.
- Pass the message ID through to downstream effects as an idempotency key (payment APIs, email providers) so retries dedupe end to end.
- Ack only after the work is durably complete. Acking first converts "duplicate" into "lost," which is worse.
- Size the visibility timeout/ack deadline above your worst-case processing time, or extend it via heartbeat — otherwise the broker creates concurrent duplicates on purpose.

**Red flags that you're about to violate this:**
- "The queue is configured for exactly-once delivery."
- "We've never seen a duplicate in this queue."
- "FIFO queues dedupe, so the handler doesn't need to."
- "I'll check if it's processed, then process it." (Not atomically? That's the race.)
- "Processing is fast, the visibility timeout won't expire."
- "Adding idempotency keys is over-engineering for an internal queue."
