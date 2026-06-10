---
title: JS Sort Numbers With a Comparator
slug: js-sort-numbers-with-comparator
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: high
one_liner: "Stops JS default sort putting 10 before 9 and mutating in place"
---

# JS Sort Numbers With a Comparator

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `array.sort()` sorting numbers as strings — and quietly mutating the array you sorted.

**[Copy-paste ready version](../../install/js-sort-numbers-with-comparator.md)** — just the instruction block, no explanation.

## The Problem

`[1, 5, 10, 25].sort()` returns `[1, 10, 25, 5]`. JavaScript's default sort converts every element to a string and compares UTF-16 code units, so `"10" < "5"` and your numbers come back in lexicographic order. The bug hides beautifully: single-digit test data sorts correctly, small arrays look plausible at a glance, and the output is *deterministically* wrong rather than randomly wrong, so it can even pass a snapshot test that was recorded against the broken output.

There's a second knife in the same drawer: `sort()` mutates the array in place *and* returns it. Code like `const sorted = items.sort(...)` looks functional but has silently reordered `items` for every other holder of that reference — a React state array, a memoized selector's cache, a prop the parent still owns. The visible symptom is usually "unrelated" UI reordering or a stale-memo bug far from the sort call.

Assistants generate bare `.sort()` because in Python, Java, and most languages the default sort of numbers is numeric. The string-comparison default is a JavaScript-only landmine, and the in-place mutation contradicts the functional style the surrounding generated code usually pretends to have.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS Sort Numbers With a Comparator

NEVER call `.sort()` without a comparator unless the elements are strings and lexicographic order is genuinely what you want. JavaScript's default sort stringifies elements and compares code units: `[1, 5, 10].sort()` yields `[1, 10, 5]`.

- Numbers: `arr.sort((a, b) => a - b)` ascending, `(a, b) => b - a` descending. This also applies to numeric strings you intend to order numerically and to dates (`(a, b) => a - b` works on Date objects via valueOf).
- Objects: sort by an explicit key, `arr.sort((a, b) => a.price - b.price)`; for string keys use `a.name.localeCompare(b.name)`, not `<`/`>` on the raw strings, if human-facing order matters.
- Mutation: `sort()` reorders the array in place and returns the same reference. If the array came from props, state, a function argument, or a shared cache, sort a copy: `arr.toSorted(cmp)` (ES2023) or `[...arr].sort(cmp)`.
- `reverse()` has the same in-place behavior; use `toReversed()` or copy first under the same conditions.
- Comparator contract: return negative/zero/positive, and be consistent — returning a boolean (`(a, b) => a > b`) is a classic generated bug that produces incomplete, engine-dependent ordering.
- Beware `a - b` on values that may be `NaN` or `undefined`; filter or map them out before sorting.

**Red flags that you're about to violate this:**

- "It's a plain array of numbers — default sort handles the simple case."
- "My test data sorts correctly, so the comparator is optional here."
- "Returning `a > b` from the comparator is shorter and means the same thing."
- "sort() returns the array, so assigning it to a new const keeps the original intact."
- "This array is local, no one else can see the mutation." (Is it? It came in as a parameter.)

---

## Why It Works

1. **It corrects a cross-language default.** The model assumes numeric default sort because nearly every other language has it; the `[1, 10, 5]` example is a concrete override of that prior.
2. **It couples the two traps.** The mutation bug rides along with almost every sort call; handling them in one rule prevents the model fixing the comparator while still trashing shared state.
3. **It bans the boolean comparator specifically.** `(a, b) => a > b` looks correct, typechecks, and breaks only on certain inputs and engines — exactly the kind of bug that needs naming, because nothing else will catch it.

## Origin

A pricing page sorted plan tiers by monthly cost with a bare `.sort()`. The $100 plan sorted between $10 and $25, and because the "recommended" badge was assigned to the middle element, the most expensive plan got badged as recommended for six days. The array was also component state, so the unsorted original was gone — the sort had mutated it in place.
