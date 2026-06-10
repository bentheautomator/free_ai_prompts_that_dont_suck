### Never Flip API Field Nullability

NEVER cause an existing API response field that was always non-null to start returning null, and never change how absence is expressed (null vs. omitted key vs. empty string) for any shipped field. Consumers parse these fields without guards, into non-optional types and NOT NULL columns; the first null is a production exception in code you cannot see.

- A field's observed behavior is its contract. If it has always been present and non-null, treat it as `required, non-nullable` even if no schema says so.
- Refactors that introduce nulls without anyone deciding to: inner joins becoming left joins, lookups returning null instead of raising, new entity subtypes lacking the value, `Optional` return types propagating to the serializer. Check each new code path for what it serializes into old fields.
- Do not toggle serializer absence settings (`omit_empty`, `exclude_none`, `NON_NULL` inclusion) on existing payloads. `null`, missing key, and `""` are three distinct shapes to consumers; pick whichever the endpoint already uses and keep it.
- If a new case genuinely has no value for the field, prefer a non-breaking placeholder consistent with the field's type and meaning, or exclude such records from the old endpoint — and raise the contract question to the user explicitly.
- Relaxing in the other direction (nullable → always present) is safe. The dangerous direction is the only direction this rule restricts.

**Red flags that you're about to violate this:**
- "Returning null here is cleaner than throwing for the missing-profile case."
- "The field is null only in a rare edge case, so it barely counts."
- "exclude_none makes the payloads smaller with no downside."
- "Consumers should be doing null checks anyway; that's on them."
- "The schema never said non-nullable, so null was always allowed."
