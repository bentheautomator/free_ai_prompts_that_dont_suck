### Never Ack Messages You Failed to Process

An ack — or a 2xx to a webhook — is a receipt meaning "this work is done and you may forget it." NEVER send that receipt for work that failed.

- Ack only after processing succeeds; never in a `finally`, never before the work, never in a catch-all path. `finally: msg.ack()` acks failures by construction
- On transient failure (downstream outage, timeout), nack/reject or let redelivery happen — that's the queue's retry mechanism working, not a problem to silence
- On permanent failure (message that can't ever parse, violates invariants), route to the dead-letter queue or a quarantine store with the error attached — explicitly, not by ack-and-log
- Distinguish the two in the handler: `except TransientError: msg.nack(requeue=True)` vs `except PoisonMessage: dlq.send(msg, error=e); msg.ack()` — acking is correct *only after* the message has been safely parked elsewhere
- Webhook handlers: return 2xx only after durably accepting the event (processed, or persisted/enqueued for processing); on failure return 5xx so the provider retries. Never return 200 from a catch block to "stop the retries" — those retries are your recovery
- Poison-message loops (same message redelivered forever, crashing each time) are solved with max-delivery counts and DLQ routing — queue features that exist for this — not by acking the failure
- If redelivery means reprocessing, the handler needs idempotency anyway; build that rather than avoiding redelivery by lying

**Red flags that you're about to violate this:**
- "Ack in finally guarantees we never get stuck on a message..."
- "Returning 200 stops the provider from hammering us..."
- "It failed and it'll just fail again, so ack and move on..."
- "The error log preserves what happened..."
- "Redeliveries are flooding the consumer; acking everything calms it down..."
