---
title: JS typeof null Is Object
slug: js-typeof-null-is-object
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: high
one_liner: "Stops typeof checks from treating null as a valid object and crashing later"
---

# JS typeof null Is Object

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `typeof x === 'object'` guards from waving `null` through and detonating three lines later.

**[Copy-paste ready version](../../install/js-typeof-null-is-object.md)** — just the instruction block, no explanation.

## The Problem

`typeof null` returns `"object"`. It has since 1995, it will forever, and a fix was formally rejected because it would break the web. So the guard `if (typeof config === 'object') { return config.timeout }` happily accepts `null` and throws `TypeError: Cannot read properties of null` on the property access — usually a few calls away from the check that was supposed to prevent exactly this.

The same family of `typeof` surprises bites adjacent code: `typeof []` is `"object"` (arrays pass object checks and then `Object.keys` iteration does something unintended), `typeof NaN` is `"number"` (a "valid number" check that admits NaN), and `typeof undeclaredVar` is `"undefined"` without throwing, which makes typo'd variable names pass existence checks silently.

Assistants generate `typeof x === 'object'` as the canonical "is this an object" test because it is the canonical test in training data — most of which never feeds it a `null`. The check reads like a complete type guard, reviews like a complete type guard, and isn't one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS typeof null Is Object

ALWAYS exclude `null` explicitly when using `typeof x === 'object'` — `typeof null` is `"object"`, so the bare check admits `null` and the crash happens at the later property access instead of at the guard.

- Plain object check: `x !== null && typeof x === 'object'`. In TypeScript, this is also what narrows the type correctly.
- Wrong: `if (typeof payload === 'object') { handle(payload.data) }` — throws on `null` payloads.
- Array vs object: `typeof` cannot tell them apart; use `Array.isArray(x)` for arrays, and check it before the generic object branch when both are possible inputs.
- "Is a valid number": `typeof x === 'number'` admits `NaN` and `Infinity`. Use `Number.isFinite(x)` when you mean a usable number.
- `typeof fn === 'function'` is fine and is the one reliable structural `typeof` check.
- Do not "simplify" `x !== null && typeof x === 'object'` to a truthiness check on `x` alone, and do not reorder it so the `typeof` runs first in a way that lets a later refactor drop the null clause.
- When the real question is "can I read properties off this," prefer validating the specific shape (`x?.data !== undefined`, a schema validator, or a TS type guard) over duck-typed `typeof` chains.

**Red flags that you're about to violate this:**

- "`typeof x === 'object'` is the standard way to check for an object."
- "This value comes from JSON.parse, so it's definitely an object." (JSON `null` parses to `null`.)
- "The null case can't happen here."
- "I'll tidy this guard up by dropping the redundant null check."
- "typeof says it's a number, so it's safe to do arithmetic with." (NaN says hello.)

---

## Why It Works

1. **It relocates the bug to the guard.** The model treats `typeof` checks as complete; stating that the failure surfaces at the *later* property access explains why its local check "looked fine" and still crashed.
2. **It hardcodes the correct two-clause idiom.** `x !== null && typeof x === 'object'` becomes the unit the model emits, instead of a base check plus an optional null clause it may omit.
3. **It bundles the sibling traps.** Arrays-as-objects and NaN-as-number are the same root cause (typeof is coarser than the model assumes); covering them in one rule stops the model fixing null and immediately tripping on `Array.isArray`.
4. **It kills the JSON rationalization.** "It came from JSON so it's an object" is the single most common justification for the bare check, and JSON `null` is the exact counterexample.

## Origin

A webhook handler guarded incoming payloads with `if (typeof body.metadata === 'object')` before reading `metadata.orderId`. One upstream integration sent `"metadata": null` for guest checkouts — valid JSON, passed the guard, threw on the property read, and the unhandled rejection made the handler return 500. The sender retried 500s, so every guest checkout webhook retried for hours and the queue backed up overnight.
