---
title: Don't Trade Clarity for Unmeasured Speed
slug: dont-trade-clarity-for-unmeasured-speed
category: performance
tags: [universal, performance]
works_with: all
severity: medium
one_liner: "Keeps simple correct code from being rewritten into clever code for no win"
---

# Don't Trade Clarity for Unmeasured Speed

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from complicating correct, readable code in the name of performance gains nobody measured and nobody needed.

**[Copy-paste ready version](../../install/dont-trade-clarity-for-unmeasured-speed.md)** — just the instruction block, no explanation.

## The Problem

You ask for a function that deduplicates a list of email addresses. You get back a hand-rolled open-addressing hash set with bit-twiddled string hashing, "for performance." Or a clean three-line implementation arrives wrapped in object pools, manual buffer reuse, and a fast-path/slow-path split — for an endpoint that handles forty requests a day. The simple version was correct, obvious, and plenty fast. The clever version is correct only probably, and every future reader pays a tax to find out.

AI assistants do this because performance-flavored code reads as senior. Training data is full of optimization war stories, and "I made it fast" is a completable, praiseworthy-sounding goal even when nobody asked. The assistant cannot feel the maintenance cost of cleverness, so the trade always looks free from where it sits.

The cost is real even when the code works: harder review, harder debugging, more edge cases, and a codebase that trains the next contributor (human or AI) to write the same way. Speculative optimization is complexity paid up front for a benefit that usually never gets collected.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Trade Clarity for Unmeasured Speed

ALWAYS write the simple, obviously-correct version first, and keep it unless a measurement on realistic data shows it misses a stated performance requirement. Complexity is a cost you pay immediately; speculative speed is a benefit that usually never arrives.

The failure is rewriting clear code into clever code (manual buffer management, hand-rolled data structures, fast-path forks, micro-tuned loops) to chase performance nobody measured and nobody asked for.

- Default to the idiomatic standard-library solution. `set(emails)` beats a hand-rolled hash table in correctness, readability, and usually in actual speed.
- An optimization may replace simple code only when all three exist: (1) a stated requirement or budget it currently misses, (2) a measurement on realistic input proving the miss, (3) a measurement proving the complex version fixes it. Otherwise ship the simple version.
- Avoiding a known catastrophic pattern (quadratic scan on unbounded input, query in a loop) is not premature optimization. That's just not writing a bug. This rule is about adding cleverness, not about avoiding known landmines.
- If you believe a hot spot is coming, leave the simple code and add a comment noting the suspected hot spot, instead of pre-paying for it in complexity.
- When the user explicitly asks for maximum speed, still show the simple version and the measured gap before replacing it.

**Red flags that you're about to violate this:**
- "This is fine, but a really optimized version would..."
- "Allocations in this loop could add up, better pool them."
- "I'll add a fast path for the common case just in case."
- "Hand-rolling this avoids the library's overhead."
- "It's a hot path, probably." (no measurement)
- "More performant code shows better engineering."

---

## Why It Works

1. **It sets the burden of proof on the complex version.** Three explicit preconditions (requirement, measured miss, measured fix) turn "could be faster" from a license to rewrite into a claim the AI must substantiate.
2. **It reframes complexity as a cost, not a credential.** The AI optimizes for looking competent; stating that cleverness is a tax flips which version reads as the senior choice.
3. **It carves out the real landmines.** Explicitly excluding known catastrophic patterns prevents the rule from being misread as "never think about performance," which would be its own failure.
4. **It offers a pressure valve.** The "leave a comment at the suspected hot spot" move satisfies the urge to do something about future performance without spending complexity today.

## Origin

A two-line date-range overlap check came back from an assistant as a 130-line interval tree "to keep lookups logarithmic." The calendar in question never held more than thirty events. The interval tree had an off-by-one in its rebalancing that surfaced four months later as ghost double-bookings, and the engineer who debugged it replaced the whole thing with the original two-line comparison. Nothing got slower. The bug had cost two days; the optimization had saved, by later measurement, about 11 microseconds per request.
