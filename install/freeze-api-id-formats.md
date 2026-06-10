### Freeze API ID Formats

NEVER change the type or format of identifiers in an existing API: integer → UUID, number → string, unprefixed → prefixed, or any change to length, casing, or structure. IDs are the only API values consumers store long-term — in their databases, URLs, and caches — so a format change breaks not just parsing but every reference already handed out.

- Both JSON type and format are frozen: `4821` (number) → `"4821"` (string) breaks typed deserializers even though the digits match. `"4821"` → `"ord_4821"` breaks everything that stored the bare value.
- Old IDs must resolve forever. Even with an internally migrated ID scheme, every endpoint that accepts an ID must keep accepting the previously-issued format and look it up correctly. An ID is a permanent ticket, not a current-schema artifact.
- Database/internal migrations (int PK → UUID) are acceptable only if the serialization boundary continues exposing and accepting the old external format — via a mapping table or dual-key lookup. The external ID and the storage key are allowed to be different things; keep them different.
- If a new format is genuinely required externally (e.g., enumeration concerns), expose it additively: a new `uuid` or `public_id` field next to `id`, with old lookups still honored, and flag the consumer-migration plan to the user.
- Numeric IDs approaching JavaScript's safe-integer limit are a real problem with the same answer: add a string twin field; do not mutate the existing field's type.

**Red flags that you're about to violate this:**
- "Sequential integer IDs are an enumeration risk; switching to UUIDs fixes it."
- "Returning IDs as strings is safer for JavaScript clients, so it's an improvement."
- "Prefixed IDs like cus_123 are industry best practice."
- "The migration maps every old ID to a new one, so nothing is lost."
- "Consumers treat IDs as opaque — format shouldn't matter to them."
