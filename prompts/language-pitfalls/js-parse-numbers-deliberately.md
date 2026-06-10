---
title: JS Parse Numbers Deliberately
slug: js-parse-numbers-deliberately
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: high
one_liner: "Stops parseInt surprises: missing radix, silent truncation, NaN leaks"
---

# JS Parse Numbers Deliberately

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents string-to-number conversions that silently truncate, misparse, or let `NaN` flow downstream.

**[Copy-paste ready version](../../install/js-parse-numbers-deliberately.md)** — just the instruction block, no explanation.

## The Problem

JavaScript gives you four ways to turn a string into a number and they all disagree. `parseInt("08")` is fine in modern engines but `parseInt(userInput)` without a radix still honors `0x` prefixes, and legacy environments treated leading zeros as octal. `parseInt("12px")` returns `12` — it parses greedily and silently discards the trailing garbage, which means `parseInt("1,200")` returns `1` and nobody notices. `Number("")` returns `0` instead of failing. And `parseInt(0.0000005)` returns `5`, because the float stringifies to `"5e-7"` first and `parseInt` reads up to the `e`.

The downstream consequence is data that looks plausible. A quantity of `1` instead of `1200` doesn't throw; it ships an order. A `NaN` from an unchecked parse propagates through arithmetic — `NaN > 0` is `false`, `NaN < 0` is `false` — and corrupts whatever comparison happens to be downstream.

Assistants reach for `parseInt(x)` with no radix and no validation because that's the dominant form in a decade of tutorials. The greedy-parse behavior is the part nobody writes about, so the model has no prior telling it `"12px"` is a trap.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS Parse Numbers Deliberately

ALWAYS choose the number-parsing function by intent, validate the result, and never call `parseInt` without an explicit radix. JavaScript's parsers disagree on whitespace, empty strings, trailing garbage, and prefixes, and most failures return a plausible number rather than throwing.

- Default for "this string should be exactly one number": `Number(str)` — it rejects trailing garbage (`Number("12px")` is `NaN`).
- Wrong: trusting `Number("")` — it returns `0`, not `NaN`. Check for empty/whitespace-only input first, or use a regex guard like `/^-?\d+$/`.
- `parseInt(str, 10)` only when you deliberately want prefix-parsing (e.g. `"12px"` to `12`), and say so in a comment. Never omit the radix.
- Never call `parseInt` on a number: `parseInt(0.0000005)` returns `5` via exponential stringification. Use `Math.trunc`/`Math.floor` to truncate numbers.
- ALWAYS check the result before using it: `if (!Number.isFinite(n)) ...`. Not `isNaN(n)` (it coerces) and not `n === NaN` (always false).
- For integers from user input, follow up with `Number.isSafeInteger(n)` when the value will index, count, or be persisted.
- Strip or reject locale formatting (`"1,200"`, `"1.200,50"`) explicitly — no parser handles it; `parseInt("1,200", 10)` returns `1`.

**Red flags that you're about to violate this:**

- "`parseInt(x)` is the standard way to read a number from a string."
- "The input comes from our own form, it'll always be clean digits."
- "If the parse fails it'll be NaN and the comparison will just be false, which is safe."
- "Adding a radix argument is redundant on modern runtimes."
- "I'll coerce with `+x`, it's the terse idiom everyone uses."

---

## Why It Works

1. **It converts a vague choice into a decision rule.** "Exact number → `Number`, prefix parse → `parseInt(_, 10)` with a comment" removes the ambiguity where the model otherwise picks the statistically common form.
2. **It makes validation part of parsing, not an extra step.** `Number.isFinite` after every parse is stated as the default shape, so "validation happens elsewhere" stops being an available excuse.
3. **It pre-empts the plausible-garbage failure.** Naming `"1,200" → 1` and `"" → 0` gives the model concrete counterexamples to its "input will be clean" prior.

## Origin

An inventory import parsed CSV quantities with `parseInt(row.qty)`. A regional supplier exported numbers with thousands separators, so `"2,500"` imported as `2`. Stock levels looked low, the auto-reorder system dutifully ordered more, and the warehouse received a quarter's worth of excess stock before anyone reconciled the counts. The parse never threw once.
