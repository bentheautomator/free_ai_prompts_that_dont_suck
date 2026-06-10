---
title: Keep Truth Tables When Simplifying Conditionals
slug: keep-truth-tables-when-simplifying-conditionals
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops boolean cleanups that quietly change which inputs take which branch"
---

# Keep Truth Tables When Simplifying Conditionals

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "simplifying" boolean logic in ways that change the truth table at the edges: null vs empty, zero vs missing, short-circuit side effects.

**[Copy-paste ready version](../../install/keep-truth-tables-when-simplifying-conditionals.md)** — just the instruction block, no explanation.

## The Problem

Boolean simplification is where refactors lie most fluently. `if (x != null && x.length > 0)` becomes `if (x)`, which reads identically and isn't: the empty string now takes the other branch in one language, the number zero in another. `if not (a and b)` becomes `if not a and not b`, a De Morgan's error that looks like algebra. A chain of `if/else if` collapses into a dict lookup that no longer falls through. `value == null` (which catches `undefined` in JavaScript) becomes `value === null` (which doesn't) because strict equality is "best practice." Each of these is a one-line change to which inputs go where, hidden inside an edit that presents as pure cleanup.

Models make these errors confidently because simplified conditionals dominate their training data and because truthiness rules vary by language while the model's instinct is an average across languages. The branch boundary cases (empty, zero, null, undefined, NaN, whitespace) are exactly the inputs nobody's test suite covers and exactly the ones real data is full of.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Truth Tables When Simplifying Conditionals

When simplifying boolean logic during a refactor, the truth table is the contract: every input that took the true branch before MUST take it after, and likewise for false. NEVER trade an explicit check for a shorter one unless they are equivalent for every value, not just the typical ones.

The inputs that differ are always the edges: null, undefined, empty string, zero, NaN, empty collections, whitespace.

- Before collapsing a condition, evaluate both versions against the edge inputs explicitly: `null`/`None`, `undefined`, `""`, `0`, `0.0`, `NaN`, `[]`, `{}`, `false`. Any divergence means the "simplification" is a behavior change.
- Truthiness shortcuts are language-specific: `if (x)` excludes `""` and `0` in JavaScript and Python but means something else entirely in Ruby, where `0` and `""` are truthy. Never apply one language's idiom to another's semantics.
- `x == null` vs `x === null` in JavaScript, `is None` vs `== None` vs `not x` in Python: these are different predicates, not style variants. Preserve the original predicate.
- Applying De Morgan's laws, distributing negations, or reordering `&&`/`||` chains must account for short-circuiting: if any operand has a side effect or can throw (`x.length` when `x` is null), reordering changes behavior.
- Replacing if/else chains with lookup tables, `switch`, or pattern matching must reproduce the original's fall-through, default, and evaluation-order semantics exactly.
- Combining nested ifs into one condition flattens which checks guard which: `if a: if b:` evaluates `b` only when `a` holds. `if a and b:` matches only if evaluating `b` is safe and effect-free when `a` is false.
- When the original logic is convoluted, restructure for readability while keeping the predicate identical, or state the truth-table change you're proposing and ask.

**Red flags that you're about to violate this:**

- "These two conditions are logically equivalent."
- "A truthiness check is idiomatic here."
- "Strict equality is always safer, so I'll upgrade this `==`."
- "I'll just distribute this negation to flatten the logic."
- "No real input would be the empty string anyway."

---

## Why It Works

1. **It supplies the edge-input checklist the model skips.** "Logically equivalent" is asserted from typical values; forcing evaluation at null/zero/empty turns the assertion into nine concrete checks, which is where every one of these bugs lives.
2. **It demotes idioms from style to semantics.** The model treats `==` vs `===` and explicit-vs-truthy as preferences; declaring them different predicates removes the license to swap.
3. **It names short-circuiting as load-bearing.** Reorderings and De Morgan transformations are algebraically valid and operationally wrong when operands throw or have effects; making evaluation order part of the truth table closes that gap.

## Origin

During a readability pass, an assistant rewrote `if (discount != null && discount > 0)` as `if (discount)`. Discounts of zero had been an explicit "no discount" record distinct from null's "not yet decided," and the new check merged them. The pricing page started showing "Discount applied: $0.00" to a few thousand users, who were exactly as confused as the support team that fielded the tickets.
