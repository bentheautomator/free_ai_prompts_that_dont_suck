---
title: JS Array Fill Shares One Object
slug: js-array-fill-shares-one-object
category: language-pitfalls
tags: [universal, javascript]
works_with: all
severity: high
one_liner: "Stops Array.fill with an object putting the same reference in every slot"
---

# JS Array Fill Shares One Object

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `new Array(n).fill({})` creating n references to one object, so writing to `grid[0]` writes to every row.

**[Copy-paste ready version](../../install/js-array-fill-shares-one-object.md)** — just the instruction block, no explanation.

## The Problem

`new Array(3).fill({count: 0})` does not create three counters. It creates one object and puts the same reference in all three slots. `arr[0].count++` then increments "all" of them, because there is no "all" — there is one. The 2D version is the classic: `new Array(rows).fill(new Array(cols).fill(0))` builds one row array shared by every row index, so `grid[2][5] = 1` lights up column 5 in every row. The code reads like initialization, the array prints correctly right after creation, and the corruption only appears on first write.

The same reference-vs-copy trap wears other JS outfits: `const copy = {...obj}` and `arr.slice()` are shallow, so nested objects are still shared; default parameter values like `function f(opts = sharedDefaults)` hand out the same object if it was defined once at module scope and later mutated.

Assistants generate `fill(new Array(...))` because it's the most compact-looking matrix initializer and because the equivalent Python bug (`[[0]*cols]*rows`) and its fix are tangled together in training data. The model knows *a* fix exists; it routinely emits the broken version first because the broken version is shorter and looks identical until mutation.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### JS Array Fill Shares One Object

NEVER initialize an array of objects (or array of arrays) with `.fill(someObjectOrArray)`. `fill` evaluates its argument once and copies the reference into every slot — mutating one element mutates them all.

- Right: `Array.from({length: n}, () => ({count: 0}))` — the callback runs per slot, producing n distinct objects.
- 2D arrays: `Array.from({length: rows}, () => new Array(cols).fill(0))`. Filling the inner array with a primitive is fine; primitives have no identity to share.
- Wrong: `new Array(rows).fill(new Array(cols).fill(0))` — one shared row; `grid[2][5] = 1` sets column 5 in every row.
- Wrong: `new Array(n).fill({})`, `.fill([])`, `.fill(new Thing())` — one shared instance.
- `.fill(0)`, `.fill(null)`, `.fill('x')` are fine: the rule is about reference types only.
- The same one-evaluation trap applies anywhere a "fresh" object is needed per use: `arr.map(() => makeDefault())` not `arr.map(x => DEFAULT)`; don't hand a module-level object out as a mutable default.
- When pre-sizing without `Array.from`: `[...Array(n)].map(() => ({}))` also works; bare `new Array(n).map(...)` does NOT (the holes are skipped and you get holes back).
- If elements are filled-then-immediately-overwritten with distinct values, `fill` as a placeholder is acceptable — but say so in a comment, because the next edit will mutate in place.

**Red flags that you're about to violate this:**

- "fill is the idiomatic way to initialize an array to a value."
- "I'll fill with an empty object and populate each slot later." (Populating via mutation hits the shared reference.)
- "This worked for the 1D zeros array, same pattern for the matrix."
- "It prints correctly, so the initialization is right."
- "JS arrays of arrays work like the nested list comprehension I'd write in Python."

---

## Why It Works

1. **It states the mechanism, not just the ban.** "fill evaluates its argument once" explains every variant, so the model generalizes to `.fill(new Thing())` instead of memorizing one banned literal.
2. **It supplies the drop-in correct idiom.** `Array.from({length}, callback)` is exactly as short as the broken version, removing the brevity incentive that makes the model pick `fill`.
3. **It separates primitives from references.** Half-learned versions of this rule make models avoid `fill(0)` too; the primitive carve-out keeps the rule precise enough to survive review.
4. **It flags the `new Array(n).map` decoy.** The "fix" the model reaches for after being told fill is wrong is mapping over holes, which silently does nothing; naming it closes the escape hatch.

## Origin

A scheduling tool initialized its week view as `new Array(7).fill({slots: []})`. Booking a Monday slot pushed into the shared `slots` array, so the appointment appeared on all seven days. It passed QA because the test booked one appointment and checked that day only — the bug shipped, and the first user report was a barber asking why one haircut had blocked out his entire week.
