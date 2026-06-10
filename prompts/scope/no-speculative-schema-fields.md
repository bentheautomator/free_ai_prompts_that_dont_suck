---
title: No Speculative Schema Fields
slug: no-speculative-schema-fields
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI adding database fields and model attributes for imagined future needs"
---

# No Speculative Schema Fields

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from padding schemas, models, and payloads with fields the request never mentioned.

**[Copy-paste ready version](../../install/no-speculative-schema-fields.md)** — just the instruction block, no explanation.

## The Problem

The ticket asks for one new column: `cancelled_at` on subscriptions. The migration that comes back adds `cancelled_at`, plus `cancellation_reason`, `cancelled_by`, `refund_status`, and a `metadata` JSON column "for future extensibility." The model grows matching attributes, the serializer exposes them in the API, and suddenly the system has four nullable fields with no writer, no reader, and no requirement behind them.

Schemas attract this padding because adding a column "while the migration is open anyway" feels efficient — migrations are ceremony, so batching feels smart. But data schemas are the most expensive place in a codebase to park a guess. Unused columns can't be dropped casually once anything might have written to them; every NULL is ambiguous (never set? legitimately empty?); the API fields become contracts the moment any client reads them, even out of curiosity; and the catch-all JSON column is a typed schema's escape hatch that future data quietly migrates into, unvalidated, unindexed, and unqueryable. Speculative fields also leak intent: an API exposing `refund_status` announces a refund feature that may never be built, and someone will build against the announcement.

When the real requirement arrives, it rarely matches the guess — `cancellation_reason` turns out to need a foreign key to a reasons table, not free text. Now there's a junk column to migrate around.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It corrects the batching economics.** "One migration now beats three later" ignores that wrong guesses produce junk columns plus the real migration anyway; naming the schema as the most expensive home for guesses fixes the cost model.

2. **It refutes "nullable is harmless."** The AI models unused columns as inert; spelling out NULL ambiguity and un-droppability shows they're active liabilities.

3. **It blocks intent leakage through APIs.** Exposed speculative fields announce features and recruit dependents; making serializers explicitly in scope of the ban closes the path from "harmless column" to "accidental contract."

4. **It routes foresight into the offer.** The AI's prediction of future needs may be right; the one-sentence suggestion preserves that value while keeping the guess out of the schema.

## Origin

A migration meant to add a single `archived_at` column also gained five speculative fields and a `metadata` JSON column. Over the following year, three features stored loosely structured data in `metadata` to avoid writing migrations, including one field the billing job started reading. When the team finally normalized it, the backfill script ran for nine hours and a missed edge case in one JSON shape corrupted billing flags for a few thousand accounts. The original ticket had been one column for one filter.
