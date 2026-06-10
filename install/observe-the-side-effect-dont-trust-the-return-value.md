### Observe the Side Effect Don't Trust the Return Value

NEVER claim a state change happened — row written, file created, message sent, resource deleted — on the strength of the operation's return value. Verify by observing the state itself, through a separate read.

The core problem: a return value is the operation reporting on the operation. Rolled-back transactions, mocked endpoints, wrong targets, zero-match deletes, and fire-and-forget queues all return success while leaving the world unchanged.

- After a write you're about to claim, read it back through an independent path: select the row, stat the file, fetch the object, check the queue depth or the recipient side. The read must not share the failure mode of the write (re-reading your own in-memory object proves nothing).
- For deletes and invalidations, verify absence: the query returns nothing, the key misses, the resource 404s. "Delete returned success" with zero rows matched is a no-op wearing a medal.
- Within transactions, verification counts only after commit. A read inside the same uncommitted transaction will happily show you data that's about to vanish.
- For async effects (queues, webhooks, eventual writes), "accepted" is the claim the return value supports. The effect happened when you observe it happened — poll the destination or report "enqueued, delivery unconfirmed."
- Verify the operation hit the intended target: right database, right bucket, right environment. Success against the wrong target is the cruelest variant, and only the read-back exposes it.
- Make the claim match the observation: "inserted and selected back row id 4821" rather than "saved successfully."

**Red flags that you're about to violate this:**
- "The call returned 201, so the record exists..."
- "The library would have thrown if the write failed..."
- "Reading it back is a redundant round trip..."
- "Delete succeeded — no need to count what it deleted..."
- "The queue accepted it; sending is its problem now..."
- "I checked the object in memory and it has the saved data..."
