### Guard Against Double Submit

Every state-creating submit MUST be idempotent at the server, enforced by something atomic. Client-side button disabling is a courtesy, not a defense; retries, refreshes, and second tabs go around it.

Two identical requests will arrive concurrently. The server must turn them into one effect.

- Generate an idempotency key client-side when the *form is shown* (not when clicked — both clicks must share the key), send it with the request, and enforce it server-side with a unique constraint or atomic insert. Second arrival gets the first result back, not an error and not a second effect.
- The enforcement must be atomic: a unique index on the key, `INSERT ... ON CONFLICT`, or an atomic set-if-absent. "Check if a request with this key exists, then insert" is itself a race and will pass both concurrent duplicates.
- Pass idempotency keys through to payment and third-party APIs that support them; otherwise your one order can still become their two charges.
- Client side, still do the courtesy: disable on submit, show progress, re-enable on failure. It prevents most duplicates from existing; the server prevents the rest from mattering.
- Retries must reuse the original key. A retry with a fresh key is just a duplicate with paperwork.
- Make the duplicate path return success with the original result. Surfacing "duplicate request" as an error teaches clients to retry harder.

**Red flags that you're about to violate this:**
- "The submit button is disabled while pending, so duplicates can't happen."
- "I check whether the order already exists before inserting." (Both requests check first.)
- "Our users wouldn't double-click a payment button." (They will. Especially that one.)
- "The network layer handles retries transparently." (That's the threat, not the defense.)
- "I'll dedupe by user + timestamp." (Two clicks in the same second share both.)
