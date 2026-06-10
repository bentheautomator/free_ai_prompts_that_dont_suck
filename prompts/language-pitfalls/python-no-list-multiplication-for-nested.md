---
title: Python No List Multiplication for Nested Structures
slug: python-no-list-multiplication-for-nested
category: language-pitfalls
tags: [universal, python]
works_with: all
severity: high
one_liner: "Stops [[0]*n]*m grids where every row is the same aliased list"
---

# Python No List Multiplication for Nested Structures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents 2D grids built with `*` where writing to one row mysteriously writes to all of them.

**[Copy-paste ready version](../../install/python-no-list-multiplication-for-nested.md)** — just the instruction block, no explanation.

## The Problem

To build a 3x3 grid, `grid = [[0] * 3] * 3` is the obvious one-liner, and it's broken. The outer `* 3` doesn't copy the inner list — it creates three references to the *same* list object. Set `grid[0][0] = 1` and you'll find `grid[1][0]` and `grid[2][0]` are now 1 too. The inner `[0] * 3` is fine (ints are immutable; aliasing them is harmless); it's multiplying a list *containing mutables* that aliases. The same trap hides in `[{}] * n`, `[set()] * n`, and `dict.fromkeys(keys, [])`, where every key shares one list.

What makes this nasty is that the grid prints correctly after construction. The corruption only appears on first write, often deep inside an algorithm, and it looks like the algorithm's logic is wrong — people debug their BFS for hours before suspecting the initializer.

AI assistants emit this constantly because `[0] * n` for flat lists is correct and idiomatic, and the model generalizes the pattern one dimension up where the semantics flip from "copy values" to "alias references."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Python No List Multiplication for Nested Structures

NEVER use list multiplication (`*`) to build a Python list whose elements are mutable (lists, dicts, sets, objects). Multiplication copies references, not objects, so all rows of `[[0]*cols]*rows` are the same list and writing one cell writes the whole column.

- Wrong: `grid = [[0] * cols] * rows` — every row aliases one list.
- Right: `grid = [[0] * cols for _ in range(rows)]` — the comprehension runs the inner expression per row, creating distinct lists.
- Wrong: `buckets = [[]] * n`, `slots = [{}] * n` — n references to one object.
- Right: `buckets = [[] for _ in range(n)]`.
- Wrong: `dict.fromkeys(keys, [])` — one shared list for every key. Right: `{k: [] for k in keys}` or `defaultdict(list)`.
- Multiplication is fine when elements are immutable: `[0] * n`, `[None] * n`, `["x"] * n` are all correct and preferred.
- Quick self-check before emitting `[X] * n`: if `X` evaluates to something mutable, rewrite as a comprehension.

**Red flags that you're about to violate this:**

- "`[[0]*cols]*rows` is the compact, Pythonic way to make a grid."
- "I printed the grid and it looks right, so the construction is correct."
- "The flat version `[0]*n` works, so nesting it must work too."
- "A comprehension with `for _ in range(...)` is uglier than multiplication."
- "fromkeys with a default list initializes every key in one call."

---

## Why It Works

1. **It locates the exact boundary.** Blanket "don't use `*` on lists" would be wrong advice; stating that the rule flips on element mutability lets the model keep the good idiom and drop the broken one.
2. **It pre-empts the visual verification trap.** The grid *looks* correct after construction; saying so disarms "I checked the output" as a defense.
3. **It gives a mechanical pre-emit check.** "Is `X` mutable? Then comprehension" is a one-step decision the model can apply without judgment.

## Origin

A seating-allocation feature initialized availability with `[[True] * seats] * rows`. Booking one seat marked that seat taken in every row, so the venue "sold out" a column at a time. The bug shipped because the demo booked exactly one seat — which looked perfectly correct — and the load test only read the grid, never wrote it.
