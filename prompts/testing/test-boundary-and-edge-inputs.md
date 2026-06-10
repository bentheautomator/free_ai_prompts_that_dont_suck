---
title: Test Boundary and Edge Inputs
slug: test-boundary-and-edge-inputs
category: testing
tags: [universal, testing]
works_with: all
severity: high
one_liner: "Suites of comfortable middle-range inputs that never probe empty, zero, or max"
---

# Test Boundary and Edge Inputs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents test suites where every input is comfortably typical and every boundary goes unprobed.

**[Copy-paste ready version](../../install/test-boundary-and-edge-inputs.md)** — just the instruction block, no explanation.

## The Problem

AI-generated test inputs cluster hard around the typical: a list of three items, a quantity of 5, a name like "John Doe", an amount of 100.00. Statistically that's exactly what the training data looks like, and it produces suites that exercise the broad middle of every function while skipping the places bugs actually live: the empty list, the single-element list, zero, negative numbers, the value exactly *at* the limit versus one past it, the empty string, the 10,000-character string, `"Ω≈ç√"`, the duplicate, the already-sorted input for a sort, February 29th. Off-by-one errors are *definitionally* invisible to mid-range inputs — a `>` that should be `>=` behaves identically for 5 when the boundary is 100.

So you get a discount function tested at 3 items and 7 items but never at the 10-item threshold its own code names; pagination tested with 25 results but never 0 or exactly one page; a parser tested on tidy ASCII forever. The suite is green, broad, and concentrated precisely where the code was never going to fail. When asked for "thorough tests," the AI delivers more mid-range cases — thoroughness as volume, not as reach.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Test Boundary and Edge Inputs

Every test suite must probe the edges, not just the middle. Typical inputs catch almost nothing — bugs concentrate at boundaries, and a `>` vs `>=` error is invisible to every input except the boundary value itself.

The core problem: comfortable mid-range cases (3 items, quantity 5, "John Doe") exercise the code where it was never going to fail, producing a green suite with no opinion about the inputs that break things.

For each input domain, deliberately cover:
- Emptiness and minimal cases: empty list/string/map, single element, whitespace-only string
- Zero and signs: 0, negative numbers anywhere a quantity/amount/index flows, -0.0 where floats matter
- Every boundary in the code, three ways: at the limit, one below, one above. If the code says `if count >= 10`, you owe tests for 9, 10, and 11 — the threshold constants in the code ARE your test-case list
- Extremes: max lengths, huge collections, values at type limits, deeply nested structures
- String hostility where strings are parsed or stored: unicode beyond ASCII, emoji, RTL text, quotes/apostrophes, leading/trailing whitespace, embedded newlines
- Duplicates and order: repeated elements, already-sorted/reverse-sorted input, ties in comparisons
- Null/None/undefined for every optional parameter, and missing-vs-present-but-empty for fields
- Read the implementation for its constants and comparisons — each numeric literal and comparison operator is a boundary someone can get wrong by one
- If the correct behavior at an edge is undefined (what SHOULD an empty cart total be?), surface the question rather than asserting your guess

**Red flags that you're about to violate this:**
- "A few representative cases cover the logic..."
- "Nobody passes an empty list to this function..."
- "I tested 5 and 50, the threshold at 10 is obviously fine between them..."
- "Standard names and ASCII keep the fixtures readable..."
- "More tests of normal usage is what thorough means..."

---

## Why It Works

1. **It explains why typical inputs are blind.** "Off-by-one errors are invisible except at the boundary" is a mechanism, not an exhortation — once stated, testing 5 and 50 around a threshold of 10 is self-evidently worthless, and the AI stops counting it as coverage.

2. **It converts edge cases from imagination to enumeration.** The AI skips edges because nothing prompts them. A concrete checklist (empty, zero, at/below/above, unicode, duplicates, null) plus "harvest the code's own constants" replaces creative effort with a procedure.

3. **It legitimizes the undefined-behavior question.** Some edges have no specified answer, and guessing produces tests that enshrine the guess. An explicit instruction to ask converts those cases into spec clarifications instead of fabricated contracts.

## Origin

A bulk-pricing function — "10 or more units ships at the pallet rate" — was covered by tests at quantities 3, 5, 25, and 100, all passing. The implementation used `> 10`. Orders of exactly 10 units were charged the higher rate for over a year; exactly-10 turned out to be the single most common bulk order size, because the sales page suggested it. Four tests, green throughout, none within nine units of the only number that mattered.
