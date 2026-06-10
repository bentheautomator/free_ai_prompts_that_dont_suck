### Freeze API Timestamp Formats

NEVER change the serialization format of an existing date or time field in an API response, request, or webhook. The format — epoch vs ISO, seconds vs milliseconds, timezone suffix, precision — is part of the contract, and every consumer has a parser built for exactly the current form.

- Forbidden conversions on shipped fields include: epoch ↔ ISO 8601, seconds ↔ milliseconds, adding/removing fractional seconds, adding/removing timezone offsets or `Z`, changing `2024-06-10` ↔ `2024-06-10T00:00:00`, and changing locale-formatted dates in any direction.
- Watch the passengers: new serializers, DateTime library upgrades, ORM swaps, and language-idiomatic defaults all reformat dates silently. After such changes, diff a real serialized payload against the old format field-by-field.
- The worst variants don't error — they shift. Seconds read as milliseconds land in 1970; a `Z` added to a local time moves every event by the UTC offset. Treat "the value still parses" as insufficient: it must parse to the same instant via the consumer's *old* code.
- Want ISO? Add a new field (`created_at_iso`) beside the old one, or serialize the new format only under a new API version. Never in place.
- If the user explicitly requests an in-place format change, state that every consumer's date parsing breaks or silently shifts, and recommend the additive path.

**Red flags that you're about to violate this:**
- "ISO 8601 is the standard; epoch timestamps are a legacy artifact."
- "The new serializer formats dates properly out of the box — I'll keep its default."
- "I'm adding timezone info, which makes the data more correct, not less."
- "It's still the same instant in time, just written differently."
- "Milliseconds are more precise, and precision can't hurt anyone."
