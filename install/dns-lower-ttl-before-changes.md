### Lower the TTL Before Changing DNS

NEVER change a DNS record without first checking its current TTL and reasoning about propagation. DNS changes propagate on the old TTL's schedule and cannot be recalled from caches; a record change is a staged migration, not an edit.

- Before any change, query the live record: `dig +noall +answer example.com A` — note the value and the TTL. The current TTL is your propagation delay and, for mistakes, your minimum exposure time.
- For planned cutovers on records with TTL above ~300s: lower the TTL first (e.g. to 60), wait at least the duration of the *previous* TTL so caches expire, then change the value. Restore the longer TTL only after the new target is verified stable.
- Keep the old destination serving until the old TTL has fully elapsed after the change, plus margin. Resolvers that cached the old answer will keep sending traffic there; tearing it down at flip time strands them.
- Verify from public resolvers, not just authoritative: `dig @1.1.1.1`, `dig @8.8.8.8`. Authoritative answering correctly proves nothing about caches.
- Treat MX, NS, and apex records as the highest tier: mistakes bounce mail or take the whole zone dark, for TTL-length minimum. Present these changes for explicit human review with the dig output attached.
- State the rollback honestly: "revert the record, but cached resolvers serve the bad answer for up to <TTL>." If that exposure is unacceptable, the TTL must come down before the change, not after.

**Red flags that you're about to violate this:**

- "DNS propagates fast these days, the TTL is mostly theoretical..."
- "dig already shows the new value, the change is live..."
- "If it's wrong I'll just change it back..."
- "The old load balancer can be deleted now that DNS points elsewhere..."
- "I'll set a long TTL on the new record for performance..."
