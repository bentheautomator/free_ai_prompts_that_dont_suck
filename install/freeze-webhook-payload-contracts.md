### Freeze Webhook Payload Contracts

NEVER change the structure, field names, event type strings, or envelope of an existing webhook payload. Webhook subscribers are external parsers you cannot see, and unlike API callers they cannot retry or re-request: an event their handler can't parse is an event lost forever.

- Frozen elements include: the event name/type string (`order.completed`), every payload key and its type, the envelope structure (`data` wrapper, `meta`, top-level vs. nested), ID and timestamp formats, and how absence is expressed (null vs. omitted).
- Subscribers route on the event type string with exact matching. Renaming an event, even trivially, means their switch statement silently falls through — delivery still returns 200, so no alarm fires anywhere.
- Evolve additively only: add new optional fields to existing payloads, or introduce entirely new event types alongside old ones. To restructure, publish a new event version (`order.completed.v2`) and keep emitting v1 until subscribers migrate.
- Webhook payload builders look like internal code because nothing in the repo reads their output. That is exactly backwards: zero internal consumers means 100% of consumers are external.
- If the user explicitly asks to change a webhook's shape, state that all current subscribers will mis-parse or drop the events with no error visible on either side, and recommend the versioned-event path with a migration window.

**Red flags that you're about to violate this:**
- "I'll rename the event to match the naming convention of the new events."
- "Wrapping the payload in a data envelope makes all our webhooks consistent."
- "Nothing in this codebase parses these payloads, so the shape is free to change."
- "Subscribers get the events over HTTP — they'll see the new fields immediately."
- "It's our outbound data; we control the format."
