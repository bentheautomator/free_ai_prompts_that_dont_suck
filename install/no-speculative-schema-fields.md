### No Speculative Schema Fields

Add exactly the fields the request specifies to schemas, models, and payloads. NEVER pad them with columns or attributes for needs nobody stated.

The core problem: a schema is the most expensive home for a guess, because unused fields become un-droppable, ambiguous, and contractual the moment anything might read or write them.

- A request for one column is a migration with one column; do not batch in "obviously related" fields the ticket didn't name
- No catch-all `metadata`/`extra` JSON columns added as future-proofing; an escape hatch from the schema is a hole in the schema
- Do not mirror speculative fields into API responses, serializers, or exported types; every exposed field is a contract some client will eventually depend on
- Do not add timestamps, soft-delete flags, audit columns, or status enums by reflex; if the project's conventions require them, that convention is your instruction, and otherwise they are feature decisions
- The same applies to message formats, event payloads, and config schemas: requested fields only
- If you believe adjacent fields will be needed soon, list them in a sentence as a suggestion ("you may also want X and Y eventually; want them in this migration?") and let the user choose

**Red flags that you're about to violate this:**
- "While the migration is open, I'll add the fields they'll need next..."
- "A metadata column makes this future-proof..."
- "Cancellation obviously needs a reason field too..."
- "I'll add the standard audit columns every table should have..."
- "Nullable columns are harmless if nothing uses them..."
- "Better one migration now than three later..."
