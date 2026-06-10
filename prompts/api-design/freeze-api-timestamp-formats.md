---
title: Freeze API Timestamp Formats
slug: freeze-api-timestamp-formats
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: critical
one_liner: "Stops epoch-to-ISO timestamp changes that break every date parser downstream"
---

# Freeze API Timestamp Formats

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing how an existing API field serializes dates and times — epoch to ISO 8601, seconds to milliseconds, naive to zoned.

**[Copy-paste ready version](../../install/freeze-api-timestamp-formats.md)** — just the instruction block, no explanation.

## The Problem

`"created_at": 1718035200` offends the modern eye, and AI assistants reliably "fix" it to `"created_at": "2024-06-10T16:00:00Z"`. ISO 8601 is the better format — human-readable, timezone-explicit, sortable as a string. None of that helps the consumer doing `new Date(created_at * 1000)`, which now computes a date from `NaN`, or the pipeline whose schema declares the column as BIGINT and starts rejecting rows.

Timestamp changes are uniquely treacherous because several of them *don't* fail loudly. Epoch seconds reinterpreted as milliseconds put events in January 1970. A naive local timestamp gaining a `Z` suffix shifts every record by the server's UTC offset — data that's wrong by exactly five hours is much harder to spot than data that's missing. Dropping or adding sub-second precision breaks string-equality comparisons and idempotency keys built from timestamps.

The conversion usually arrives as a passenger: a new serializer's default date handling, a DateTime library upgrade, or a model rewrite where the AI picks the idiomatic format for the language. The field name never changes, so the diff looks harmless.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It separates the instant from its encoding.** The AI's rationalization is "same moment, better format"; stating that the parser, not the moment, is the contract dissolves that argument.
2. **It names the silent-shift failures** (1970 dates, UTC-offset drift), which the AI's "does it still parse?" self-check would otherwise pass.
3. **It flags the delivery vehicles** — serializer defaults, library upgrades — so the rule fires during refactors where no one typed the word "timestamp."
4. **It requires validation through the consumer's old parser**, a concrete test that replaces the vague goal of "backward compatible."

## Origin

A serializer migration changed `occurred_at` from epoch seconds to epoch milliseconds — one library flag, never mentioned in the task. A downstream analytics consumer multiplied by 1000 as it always had, landing every event around the year 56,000, where its retention logic classified them as invalid future data and dropped them. Five days of product analytics vanished before a dashboard flatlined obviously enough for someone to trace it back.
