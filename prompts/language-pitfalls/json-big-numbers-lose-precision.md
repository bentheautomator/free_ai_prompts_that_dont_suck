---
title: JSON Big Numbers Lose Precision
slug: json-big-numbers-lose-precision
category: language-pitfalls
tags: [universal, cross-language]
works_with: all
severity: critical
one_liner: "Stops 64-bit ids in JSON being rounded by double-precision parsers"
---

# JSON Big Numbers Lose Precision

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents 64-bit ids and timestamps sent as JSON numbers from being silently rounded to the nearest representable double on the other end.

**[Copy-paste ready version](../../install/json-big-numbers-lose-precision.md)** — just the instruction block, no explanation.

## The Problem

JSON the format puts no limit on number size. JSON parsers do. JavaScript's `JSON.parse` reads every number into a double, which has 53 bits of integer precision — anything above `Number.MAX_SAFE_INTEGER` (9,007,199,254,740,991) gets rounded to the nearest representable value. Snowflake-style ids are 64-bit: `JSON.parse('{"id": 9007199254740993}')` yields `9007199254740992`. Off by one, no exception, no warning. Round-trip it and you've written back a *different entity's id*. The same trap exists in any language when the field is deserialized into a double/float — and in some parsers that normalize numbers even in pass-through proxying.

The bug is invisible in development because test ids are small. It appears only when real ids cross 2^53 — which, for services that allocate ids from timestamps or shard counters, happens on a schedule. Then lookups miss, the wrong records update, and the corruption is permanent because the original digits are gone.

Assistants model ids as numbers because they look like numbers: the schema says `integer`, the example payload has digits, and `id: number` is the natural TypeScript completion. The model also "fixes" string ids into numbers during refactors, because parsing a numeric string into a number reads like type hygiene.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JSON Big Numbers Lose Precision

NEVER represent 64-bit integers (ids, snowflakes, nanosecond timestamps, cursors) as JSON numbers when any consumer might parse them as doubles. Above 2^53 (about 9.0e15), doubles silently round: `9007199254740993` parses as `...992`, and the corrupted id round-trips without error.

- Serialize 64-bit ids as JSON strings: `{"id": "9007199254740993"}`. APIs that must stay compatible can send both (`id` numeric legacy, `id_str` canonical) — consumers must use the string.
- In JavaScript/TypeScript, type ids as `string`. Never `parseInt`/`Number()` an id "to clean it up" — ids are opaque tokens; they're compared, stored, and passed, never used in arithmetic.
- If you must parse JSON containing large numerics you don't control, use a parser with bigint/raw-number support (`JSON.parse` reviver with source access where available, or a lossless-JSON library); stock `JSON.parse` has already destroyed the value by the time you see it.
- Server side: declare ids as strings in the schema (OpenAPI `type: string`), even when the database column is BIGINT. Convert at the storage boundary, not in transit.
- Proxies, loggers, and tools that parse-then-restringify JSON corrupt large numbers in payloads they merely forward — treat any parse step in the pipeline as a consumer.
- Floats in JSON have the cousin problem (decimal fractions are approximations); money amounts follow the same rule: strings or integer minor units, not JSON decimals.
- Small bounded integers (counts, ports, enum-ish codes) remain plain JSON numbers. The rule is about 64-bit-range values and opaque identifiers.

**Red flags that you're about to violate this:**

- "The id is an integer, so the JSON type should be a number."
- "I'll parse the id to a number for the comparison."
- "Our ids are nowhere near 2^53." (Snowflake ids passed it years ago; yours are timestamp-prefixed too.)
- "The API docs show the id without quotes."
- "I'm just reformatting the JSON, not changing values." (Your formatter parses it first.)
- "TypeScript says number, so number is correct."

---

## Why It Works

1. **It reframes ids as opaque tokens.** The root error is semantic — treating an identifier as arithmetic data; once ids are "strings that happen to contain digits," every downstream choice (type, parse, schema) falls out correctly.
2. **It gives the exact cliff.** 2^53 and the `...993` to `...992` example make the failure concrete and checkable, replacing a vague "big numbers are risky" with a testable boundary.
3. **It extends the consumer set to middleware.** Parse-and-restringify proxies are the non-obvious corrupters; naming them stops the model from declaring the payload safe because "our client uses strings."
4. **It blocks the type-hygiene refactor.** Converting string ids to numbers looks like cleanup and is named here as the regression it is.

## Origin

A moderation dashboard displayed content ids fetched from an upstream API. The backend sent 64-bit ids as JSON numbers; the frontend parsed them, rounded the large ones, and the "delete" button posted the rounded id back. Moderators were deleting records adjacent to the ones they'd flagged — the targeted post survived and an innocent neighbor died. It took weeks to notice because the UI confirmed deletion of the id it had *displayed*, which was the same wrong number.
