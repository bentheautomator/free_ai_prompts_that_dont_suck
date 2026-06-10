---
title: Never Flip API Field Nullability
slug: never-flip-api-field-nullability
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops shipping null in response fields that consumers were promised non-null"
---

# Never Flip API Field Nullability

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from making a guaranteed non-null response field nullable, or swapping null for field omission, in payloads consumers already parse.

**[Copy-paste ready version](../../install/never-flip-api-field-nullability.md)** — just the instruction block, no explanation.

## The Problem

A response field that has never been null is a promise, whether or not anyone wrote it down. Consumers built on that promise: they call `.email.toLowerCase()` without a guard, deserialize into a non-optional struct, write the value into a NOT NULL column. Then the AI refactors the handler — switches a join to a left join, makes a lookup failure return `null` instead of raising, adds a code path for a new record type that lacks the value — and `"email": null` starts appearing in the wild. Every unguarded consumer throws, and strict deserializers (Kotlin, Swift, Rust, anything with codegen from OpenAPI) reject the entire payload, not just the field.

The sibling failure is shuffling *how* absence is expressed. `null` versus key-omitted versus `""` look interchangeable from the server, and AI assistants swap between them freely when changing serializers — `omit_empty` flags, `NON_NULL` inclusion settings, `exclude_none=True`. To consumers, they're three different shapes: `"key" in obj` checks, JSON Merge Patch semantics, and schema validators distinguish all three.

The AI flips nullability because it's focused on making the new code path total — every case returns *something* — and `null` is the easiest something. Whether anything downstream can digest a null never enters the diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It promotes observed behavior to contract**, closing the loophole the AI loves most: "the schema technically permits null." Consumers code against what the API does, not what it reserved the right to do.
2. **It lists the null-introducing refactors by name** (left joins, Optional propagation, subtype gaps), so the check fires during changes that never mention nullability.
3. **It distinguishes null / omitted / empty as three shapes**, preempting the serializer-settings shuffle the AI performs as a harmless cleanup.
4. **It rejects "consumers should null-check" explicitly** — true, irrelevant, and the exact thought that precedes shipping the null.

## Origin

A refactor changed a profile lookup from raising on missing data to returning null, and `display_name: null` reached production for a handful of half-migrated accounts. A partner's strongly-typed client deserialized the whole user list into non-optional models, so one null name didn't break one row — it failed the entire response, taking their integration down for every account. The patch was a single fallback string; the partner's trust took longer to restore.
