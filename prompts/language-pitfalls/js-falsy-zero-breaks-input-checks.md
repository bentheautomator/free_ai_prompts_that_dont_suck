---
title: JS Falsy Zero Breaks Input Checks
slug: js-falsy-zero-breaks-input-checks
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: high
one_liner: "Stops JS truthiness checks from rejecting 0, empty string, and false"
---

# JS Falsy Zero Breaks Input Checks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `if (!value)` guards that treat `0`, `""`, `false`, and `NaN` as "missing" and silently reject valid input.

**[Copy-paste ready version](../../install/js-falsy-zero-breaks-input-checks.md)** — just the instruction block, no explanation.

## The Problem

`if (!quantity) throw new Error("quantity is required")` is the most natural-looking validation in JavaScript, and it is wrong for any field where `0` is a legal value. JavaScript has seven falsy values — `false`, `0`, `-0`, `0n`, `""`, `null`, `undefined`, `NaN` — and the `!` operator cannot tell "the caller didn't send this" apart from "the caller sent zero." The same trap hides in defaults: `const port = config.port || 3000` silently overrides an explicit `port: 0`, and `name || "anonymous"` erases an intentional empty string.

The consequence is a bug class that passes every happy-path test. Quantity 0 line items get rejected as "missing." A discount of 0% becomes the default 10%. A boolean setting explicitly set to `false` reverts to its default `true`. These surface as confused user reports, not stack traces.

AI assistants generate this constantly because `if (!x)` is the statistically dominant presence-check in training data, and in most example code the values happen to be objects or non-empty strings where it works. The model learned the shorthand, not the edge cases.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS Falsy Zero Breaks Input Checks

NEVER use bare truthiness (`if (!x)`, `x || default`) to test whether a JavaScript value is present when `0`, `""`, `false`, or `NaN` are valid values for it. Truthiness conflates "absent" with eight different legitimate values.

- Wrong: `if (!amount) throw new Error("amount required")` — rejects a valid `amount` of `0`.
- Right: `if (amount === undefined || amount === null)` or `if (amount == null)` (the one acceptable use of `==`: it matches exactly `null` and `undefined`).
- Wrong: `const limit = options.limit || 100` — an explicit `limit: 0` becomes `100`.
- Right: `const limit = options.limit ?? 100` — nullish coalescing only falls through on `null`/`undefined`.
- Wrong: `enabled = flags.enabled || true` — this can never be `false`. Use `??`.
- Bare truthiness is fine when the value is genuinely binary-shaped: objects, arrays, class instances, or strings where empty means absent by the function's own contract. State that contract in a comment if you rely on it.
- When checking for a property's existence vs. its value, use `'key' in obj` or `obj.key !== undefined`, not `obj.key` alone.
- For numbers that must be real numbers, check `Number.isFinite(x)`, not `x` or `!isNaN(x)`.

**Red flags that you're about to violate this:**

- "`if (!x)` is the idiomatic way to check for missing values."
- "Nobody would ever pass zero here."
- "`||` with a default is shorter and reads better than `??`."
- "The existing code uses `!x` checks, so I'll match the style."
- "Empty string is basically the same as not provided."
- "I'll keep the guard simple; validation happens elsewhere anyway."

---

## Why It Works

1. **It severs a false equivalence the model relies on.** Training data overwhelmingly uses `!x` where it happens to be safe; the rule states explicitly that "falsy" and "absent" are different predicates, which is the distinction the shorthand erases.
2. **It supplies the drop-in replacements.** `?? `, `== null`, and `Number.isFinite` are named as defaults, so the model substitutes instead of reasoning from scratch.
3. **It names the rationalizations.** "Nobody would pass zero" and "match the existing style" are the exact thoughts emitted right before the bug; listing them interrupts the completion.
4. **It carves out the legitimate cases.** By stating when truthiness is fine, the rule avoids being so absolute that the model abandons it on the first counterexample.

## Origin

A checkout service used `if (!item.discount) item.discount = DEFAULT_DISCOUNT` to backfill a new field. A promotional campaign legitimately set `discount: 0` on full-price bundle items; the guard rewrote every one of them to the 15% default. The pricing tests all used non-zero discounts, so nothing failed until finance asked why margin on bundles had dropped for an entire weekend.
