---
title: Never Coerce Parse Failures to Zero
slug: never-coerce-parse-failures-to-zero
category: error-handling
tags: [universal, errors, fallbacks]
works_with: all
severity: critical
one_liner: "AI turning unparseable values into 0 or empty string, corrupting real data"
---

# Never Coerce Parse Failures to Zero

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents bad input from being laundered into legitimate-looking zeros that flow into stored data.

**[Copy-paste ready version](../../install/never-coerce-parse-failures-to-zero.md)** — just the instruction block, no explanation.

## The Problem

A CSV import hits a price cell containing `"N/A"`, and the AI's defensive parsing handles it: `try: price = float(raw) except ValueError: price = 0.0`. The import completes without complaint. There is now a product priced at $0.00 in the database — not flagged, not quarantined, just *priced at zero*, indistinguishable from an actual free item. The same move appears as `int(x or 0)`, `parseInt(s) || 0` in JavaScript (where `NaN` is falsy, so every parse failure becomes 0), `Number(s) || 0`, empty-string fallbacks for failed text decoding, and epoch-zero timestamps for unparseable dates — suddenly events from 1970.

This is distinct from falling back to defaults at the config layer or returning empty lists from failed fetches: here the corruption happens *per-value, inside the data itself*, and then gets written somewhere permanent. Each coerced zero is a small lie inserted into a dataset, and zeros are arithmetic-active — they pull down averages, zero out multiplications, pass `>= 0` validations, and sail through any check that doesn't specifically suspect them.

Models generate the coercion because a parse failure mid-pipeline is an inconvenient stop, and `0` is the value-shaped object nearest to hand. The type checker is satisfied. The data is poisoned.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Coerce Parse Failures to Zero

When a value fails to parse, the result is a missing/invalid value — NEVER a fabricated `0`, `""`, `NaN`-coerced default, or epoch date. Zero is a real value with real arithmetic consequences; an unparseable input is not evidence the value was zero.

- `except ValueError: price = 0.0`, `parseInt(s) || 0`, `Number(x) || 0`, `int(x or 0)` — all forbidden as parse-failure handling; they manufacture data
- On parse failure, do one of: raise with the offending value and field (`f"row {n}: can't parse price {raw!r}")`; mark the field explicitly invalid/missing (`None`, `Optional`, a validation error list); or route the record to a reject/quarantine path — never proceed with a fabricated value
- In JavaScript, never use `|| 0` after a numeric parse — `NaN` is falsy, so the idiom converts every failure to 0 silently; check `Number.isNaN(n)` and handle it as the failure it is
- A genuine default is only valid when *absence* is expected and the default is a documented business rule (`quantity defaults to 1 when omitted`) — and even then, apply it for absent values, not for present-but-garbage values, which must error
- Dates deserve special paranoia: a parse fallback of `new Date(0)` or `datetime.min` plants events in 1970; fail or null, never epoch
- If invalid values are written anywhere persistent, the corruption outlives the bug; treat parse coercion near a database write or file output as the highest-severity form of this mistake

**Red flags that you're about to violate this:**
- "Zero is a safe default if the number won't parse..."
- "|| 0 handles the NaN case..."
- "The import shouldn't fail over one bad cell..."
- "Empty string is harmless if decoding fails..."
- "We can clean up weird values later; let's get the data in..."

---

## Why It Works

1. **It severs "value-shaped" from "valid."** The model reaches for 0 because it satisfies the type. Stating that zero is arithmetic-active — it averages, multiplies, and validates like real data — exposes why it's the *worst* placeholder, not a neutral one.

2. **It distinguishes absent from garbage.** The legitimate-default carve-out exists, but only for absence; making present-but-unparseable always an error removes the gray zone the coercion lives in.

3. **It flags the JS-specific trap as syntax.** `|| 0` after parsing is a one-idiom bug the model emits from sheer training frequency; calling out the exact token sequence catches it at generation time.

4. **It ranks persistence as the multiplier.** A coerced zero in a local variable is a bug; a coerced zero written to the database is corruption with a half-life. Tying severity to the write makes the model most careful exactly where it matters.

## Origin

A migration script written by an assistant moved historical sales data between systems, with `float(value or 0)` guarding every numeric field. Source rows used `"—"` for not-applicable amounts; thousands of them became $0.00 transactions. Quarterly revenue dashboards dipped, an analyst spent days hunting a "reporting bug," and the team eventually had to diff against archived exports of the legacy system to find which zeros were real. The script had reported a flawless migration, which in a narrow sense was true: every row arrived. Some of them just arrived as fiction.
