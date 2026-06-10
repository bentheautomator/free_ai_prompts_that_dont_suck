---
title: No Quadratic Loops on User-Sized Input
slug: no-quadratic-loops-on-user-sized-input
category: performance
tags: [universal, performance, scaling]
works_with: all
severity: high
one_liner: "Stops nested scans over data that grows with users from going quadratic"
---

# No Quadratic Loops on User-Sized Input

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping O(n²) patterns — nested scans, `includes` inside loops, pairwise comparisons — over collections whose size is set by users, not by the code.

**[Copy-paste ready version](../../install/no-quadratic-loops-on-user-sized-input.md)** — just the instruction block, no explanation.

## The Problem

`items.filter(a => other.some(b => b.id === a.id))`. A dedupe written as `if item not in result: result.append(item)` against a list. A "find conflicts" feature comparing every record to every other record. Each is linear-looking code hiding a linear operation inside, and the product is quadratic. At 100 elements that's 10,000 steps — nothing. At 100,000 elements it's 10,000,000,000 steps, and the request that took 4ms in the demo takes 11 minutes in production, if the worker doesn't get killed first.

AI assistants emit these shapes constantly because they're the most direct transcription of the requirement: "items that are also in the other list" reads as a loop with a membership test, and `in`/`includes`/`indexOf` hide their linear scans behind one English-looking word. Small test fixtures guarantee the pattern survives review and CI, because quadratic and linear are indistinguishable at n=20.

The distinguishing question is what sets n. A loop over the seven days of the week can be as nested as it likes. A loop over orders, contacts, uploaded rows, or log lines is sized by users and growth, which means the input will eventually be 1,000 times larger than the fixture, and the quadratic version will be 1,000,000 times slower instead of 1,000.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Quadratic Loops on User-Sized Input

NEVER nest a linear operation inside a loop when both scale with user data. The product of two user-sized dimensions is a quadratic, and quadratics on growing data are delayed outages: invisible at n=100, fatal at n=100,000.

The hidden forms matter more than the obvious double-`for`: `arr.includes(x)`, `list.index()`, `x in somelist`, `arr.indexOf`, `.find(...)`, `remove()` on a list, and string `in` on a growing haystack are all linear scans wearing one-word costumes. Any of them inside a loop over user-sized data is the bug.

- Membership tests inside loops use hashed structures: build a `set`/`Map`/`dict` of keys once (O(n)), then test in O(1). Intersection, difference, and dedupe are set operations, not nested scans.
- Pairwise "compare everything to everything" usually collapses by grouping: bucket by the join key (dict of lists), then compare within buckets. Sort-then-scan handles ranges, overlaps, and adjacency in O(n log n).
- Repeated `list.remove()`/`splice()` inside a loop is the same trap (each removal shifts the tail); collect survivors into a new collection instead.
- Loops over fixed, code-sized collections (enum values, config keys, days of the week) are exempt. Classify each loop: is n set by the code, or by users and time? Only the second kind is dangerous.
- Verify with a scaling check: run the path at n=1,000 and n=10,000. Linear-ish means about 10x the time; if it's closer to 100x, you shipped the quadratic. State the expected complexity in the PR description for any loop over user-sized data.

**Red flags that you're about to violate this:**
- "includes() is a method call, not a loop."
- "Both lists are small in every case I've seen."
- "A set feels like overkill for a simple check."
- "The nested version is more readable."
- "If it gets slow we can optimize later." (later is an incident)
- "The tests run instantly."

---

## Why It Works

1. **It unmasks the one-word scans.** The AI treats `includes`/`in` as primitives; enumerating them as "linear scans wearing costumes" makes the inner loop visible where the failure actually hides.
2. **It provides the classification question.** "Is n set by code or by users?" is decidable at write time and separates the harmless nested loop from the time bomb, so the rule doesn't ban nesting wholesale.
3. **It maps each shape to its fix.** Membership goes to sets, pairwise goes to grouping or sort-then-scan; with the replacement named, the quadratic is never the path of least resistance.
4. **It detects by ratio, not by reading.** The 10x-input/100x-time check catches quadratics empirically, including ones laundered through helper functions where pattern inspection fails.

## Origin

A CRM's "import contacts" feature checked each incoming row for duplicates with `existing.some(c => c.email === row.email)`. Onboarding demos imported 200 rows: instant. The first enterprise customer imported 400,000 contacts into an account that already had 300,000, and the import job ran for two days before anyone believed it wasn't hung — it was doing 120 billion string comparisons, faithfully and in order. A `Set` of existing emails built up front took the same import to four minutes. QA's fixtures had never exceeded 500 rows, which is why the pattern had survived three releases.
