---
title: Don't Memoize Cheap or One-Shot Work
slug: dont-memoize-cheap-or-one-shot-work
category: performance
tags: [universal, performance]
works_with: all
severity: medium
one_liner: "Stops reflexive memoization of cheap, impure, or never-repeated calls"
---

# Don't Memoize Cheap or One-Shot Work

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wrapping everything in memoization decorators when the work is cheap, the inputs never repeat, or the function isn't pure.

**[Copy-paste ready version](../../install/dont-memoize-cheap-or-one-shot-work.md)** — just the instruction block, no explanation.

## The Problem

Memoization has good PR, so AI assistants apply it like seasoning: `@lru_cache` on a function that adds two numbers, `useMemo` around a string ternary, a hand-rolled `cache = {}` in front of a formatter that's called once per unique input ever. Each of these adds hashing, lookup, and bookkeeping that costs more than the work being saved — or saves nothing because no key is ever seen twice. The hit rate is zero; the overhead and complexity are permanent.

Worse than useless memoization is harmful memoization. `@lru_cache` on a method holds `self` alive forever (a memory leak wearing a performance costume). Memoizing a function that reads the clock, hits the database, or depends on mutable state freezes its first answer and serves it forever after — a correctness bug introduced in the name of speed. And memoizing functions that take mutable arguments (lists, dicts) either crashes on unhashability or silently keys on identity.

The root cause is that memoization is the optimization easiest to apply without understanding the code: it bolts on at the function boundary and looks like diligence. Whether it *pays* depends on three things the assistant rarely checks: the work must be expensive, the inputs must repeat, and the function must be pure.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Memoize Cheap or One-Shot Work

NEVER add memoization (`lru_cache`, `useMemo`, `computed`, hand-rolled result caches) unless all three are true: the computation is expensive, the same inputs actually recur, and the function is pure. Memoization that fails any of the three is overhead at best and a leak or stale-data bug at worst.

- Expensive: the work must cost meaningfully more than a hash-plus-dict-lookup. Arithmetic, string formatting, simple conditionals, and property access never qualify.
- Recurring: estimate the hit rate before adding the cache. If keys are unique per call (request IDs, timestamps, user-typed strings), the hit rate is zero and the cache is a pure cost — possibly an unbounded one.
- Pure: the function must depend only on its arguments. Memoizing anything that reads the clock, randomness, a database, config, or mutable state serves a frozen first answer forever. That's a correctness bug, not an optimization.
- Know the trap variants: `lru_cache` on instance methods pins `self` (and everything it references) in the cache; mutable arguments make keys unreliable; module-level caches in long-lived processes need the same bounding as any cache.
- In UI frameworks, don't reflexively wrap every value in `useMemo`/`useCallback`; the dependency tracking itself has a cost and most values are cheaper to recompute. Reserve it for measured re-render or recompute problems.
- Verify by measuring with and without, on realistic call patterns, and by logging the hit rate. A memo with a sub-50% hit rate on cheap work should be deleted.

**Red flags that you're about to violate this:**
- "Caching this can't hurt."
- "I'll memoize it while I'm here, as a best practice."
- "This might be called with the same arguments sometimes."
- "useMemo on everything keeps renders fast."
- "It reads config, but config basically never changes."
- "The decorator is only one line."

---

## Why It Works

1. **It replaces an aesthetic with a checklist.** "Expensive, recurring, pure" turns "memoization is good" into three verifiable predicates, and most reflexive memos fail at least one on inspection.
2. **It names the correctness failure explicitly.** "Frozen first answer served forever" reframes memoizing impure functions as a bug category, not a performance trade, which weights it correctly against the perceived win.
3. **It catalogs the trap variants.** The `self`-pinning and mutable-key cases are non-obvious enough that the AI won't derive them; listing them makes them recognizable.
4. **It makes hit rate the exit criterion.** Requiring a measured hit rate gives a concrete rule for removing memos, so the cruft doesn't ratchet up monotonically.

## Origin

A code review of an AI-assisted PR found fourteen new `@lru_cache` decorators in one service. One was on `get_current_quarter()` — which reads the date — and it pinned Q3 well into October, quietly mislabeling three weeks of financial rollups until an analyst noticed the numbers never moved. Twelve of the other thirteen had hit rates under 2% when someone finally logged them. The fix deleted thirteen decorators, kept one (an actually-expensive tax table parse), and added "is it pure?" to the review checklist.
