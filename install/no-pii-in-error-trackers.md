### Scrub PII Before It Reaches Error Trackers and Analytics

NEVER send personal data to third-party telemetry (error trackers, analytics, session replay, tracing) as debugging or tracking context. Identify users by opaque internal ID; allowlist every attached field.

Telemetry vendors are an unaudited copy of whatever you send them, with their own retention, access, and breach surface. Context that includes PII is a privacy incident on a delay.

- Identify users as `setUser({ id: internalId })`. Do not attach email, name, phone, addresses, or usernames to events; if support needs to find a user's errors, the internal ID is searchable on both sides.
- Never attach whole objects as context: request bodies, form state, Redux/app state, user records, or `extra: req.body`. Attach named, individually chosen fields.
- Configure the SDK's scrubbing: `beforeSend` hooks to delete known-sensitive keys, server-side data scrubbers, and denylists for field names (`password`, `email`, `ssn`, `token`, `card`). Turn ON the SDK's default PII filters and leave `sendDefaultPii`-style options OFF.
- Session replay and heatmap tools: mask all inputs by default (`maskAllInputs: true` or equivalent), and explicitly block replay on pages handling payments, health data, or identity documents.
- Analytics events carry the same rule: `signup_completed` with a plan name is fine; with the user's email and company as event properties, it's PII replication. Marketing can join on the internal ID server-side.
- URLs leak too: if routes embed emails or names (`/users/jane@example.com`), telemetry inherits them; route by ID and the problem disappears upstream.
- Regulated categories (health, payment card data, government IDs) must never reach general-purpose telemetry, full stop; that's a compliance boundary, not a scrubbing preference.

**Red flags that you're about to violate this:**
- "Attaching the user object makes every error instantly debuggable..."
- "The error tracker is a trusted vendor, it's not like posting publicly..."
- "Support wants to search errors by email, so email has to be on the event..."
- "Session replay needs real inputs to be useful for UX research..."
- "It's just the email address, hardly sensitive data..."
- "We can add scrubbing once the privacy team asks for it..."
