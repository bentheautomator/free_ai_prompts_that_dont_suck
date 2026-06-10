---
title: Freeze API Numeric Field Types
slug: freeze-api-numeric-field-types
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops int-to-float and number-to-string changes on fields consumers parse typed"
---

# Freeze API Numeric Field Types

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing a numeric field's JSON type or representation — integer to float, number to string, precision changes — under consumers with typed parsers.

**[Copy-paste ready version](../../install/freeze-api-numeric-field-types.md)** — just the instruction block, no explanation.

## The Problem

JSON has one number type; consumers don't. The `"quantity": 5` your API emits is deserialized somewhere as an `int`, a `Long`, an `i64`, a Decimal — and the moment the AI's refactor makes it `5.0` (a float crept in via division, a unit conversion, or a DB column change), strict parsers start throwing `expected integer, got float`. The reverse migration is just as common: the AI, rightly nervous about float precision in money fields, converts `"price": 19.99` to `"price": "19.99"` — string-encoded decimals, genuinely better design, and an immediate type error in every consumer that declared the field numeric.

Then there are the changes that don't even throw. A rounding change from two decimal places to four makes consumer-side equality checks and checksums fail intermittently. Scientific notation (`1.2e+7`) appears for large values after a serializer swap and confuses ad-hoc parsers. An int that exceeds JavaScript's `Number.MAX_SAFE_INTEGER` starts silently corrupting in JS consumers — and the AI's fix, stringifying the field, breaks the non-JS consumers instead.

The AI changes numeric representation as a by-product of internal type hygiene: better money types, more precise columns, cleaner math. Each is an improvement in the language's type system and a mutation in the wire contract, and only one of those is visible in the diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Freeze API Numeric Field Types

NEVER change the JSON type or representation of an existing numeric field: integer ↔ float, number ↔ string, precision/rounding, or notation. Consumers deserialize numbers into declared types — `int`, `Long`, `Decimal` — and a representation change either throws in their parser or silently shifts their math. JSON's single number type is an illusion; the consumer's type is the contract.

- An integer field emits integers forever: `5`, never `5.0`. Internal changes that introduce floats (division, unit conversion, column type changes, ORM casts) must be rounded or cast back to int at the serialization boundary.
- Do not convert numeric fields to strings — even for the good reasons (decimal precision, JS big-integer safety). The fix for those is a NEW string field (`price_decimal`, `id_str`) alongside the unchanged numeric one, so consumers opt in.
- Preserve emitted precision and rounding: a field that has always shown two decimal places keeps showing two. Consumers compare, checksum, and re-display these values verbatim.
- Serializer swaps can change number rendering wholesale — scientific notation thresholds, trailing-zero handling, max precision. After any serializer change, diff real payloads for numeric fields specifically; "the values are mathematically equal" is not the test, byte equality is.
- If the user asks to change a numeric representation in place, identify the consumer classes that break (strict typed parsers throw; loose ones mis-compute) and steer to the additive-field path.

**Red flags that you're about to violate this:**
- "Using a proper Decimal type end-to-end is strictly more correct for money."
- "String-encoding large IDs protects JavaScript clients from precision loss."
- "5 and 5.0 are the same number; no consumer could care."
- "The extra decimal places only add precision — nothing is lost."
- "The new serializer renders numbers more accurately by default."

---

## Why It Works

1. **It relocates the contract from JSON's type to the consumer's type.** The AI reasons "JSON has only numbers, so numeric changes are internal"; naming the typed deserializers on the other end makes int-vs-float a visible boundary.
2. **It blocks the virtuous-motive conversions** (decimal strings, stringified big ints) by routing each to an additive twin field — acknowledging the problem is real keeps the AI from treating the rule as ignorance.
3. **It sets byte equality, not mathematical equality, as the test**, eliminating the "same value, different rendering" loophole that precision and notation changes hide behind.
4. **It names serializer swaps as a wholesale numeric-rendering event**, prompting a payload diff in exactly the change where nobody typed a single digit.

## Origin

A column migration from INTEGER to NUMERIC — to support a new fractional-units feature — flowed through the ORM and turned `"units": 12` into `"units": 12.0` across an inventory API. A warehouse system's strongly-typed client failed deserialization on every product payload and fell back to its cached catalog, which it served for six days without anyone noticing the staleness. The fix was an integer cast in one serializer line; the lingering cost was a week of fulfillment decisions made on frozen inventory numbers.
