---
title: No Unrequested Performance Work
slug: no-unrequested-performance-work
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: high
one_liner: "AI adding caches and micro-optimizations nobody asked to be faster"
---

# No Unrequested Performance Work

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding caching, memoization, and micro-optimizations to code nobody said was slow.

**[Copy-paste ready version](../../install/no-unrequested-performance-work.md)** — just the instruction block, no explanation.

## The Problem

You asked for a correctness fix; the diff adds an `@lru_cache`, converts a list to a generator, batches two queries into one, and replaces a readable loop with a clever one-liner — "while optimizing the function." No one measured anything. No one said it was slow. The AI optimized because optimization is what impressive code looks like.

Unrequested performance work carries a uniquely nasty risk profile. Caching is the classic case: a memoized function is a correctness bet that its inputs fully determine its outputs and that staleness is acceptable — a bet the AI placed on the user's behalf without mentioning it. Cache invalidation bugs surface as intermittent, unreproducible wrongness weeks later. Query batching changes transaction boundaries. Generators change when side effects run and whether data can be iterated twice. Each "optimization" is a semantic change justified by a performance problem that was never demonstrated to exist.

Meanwhile the readable version of the code is gone, replaced by something the team must now decode during every future change — to save microseconds in a function that runs four times a day.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Unrequested Performance Work

Do not optimize code unless the task is performance or the request names a speed problem. NEVER add caching or memoization on your own initiative.

The core problem: optimizations are semantic bets (staleness tolerance, evaluation order, transaction boundaries) placed without measurement against a problem nobody demonstrated, traded for readability everybody loses.

- No caches, memoization, or precomputation added to a task that isn't about performance; caching changes correctness assumptions, not just speed
- No rewriting clear code into "faster" forms (loops to comprehensions-for-speed, lists to generators, string building tricks) while doing unrelated work
- No combining, batching, or reordering of queries and I/O calls in passing; these change failure and transaction semantics
- Choosing a sensible algorithm for new code you're writing is normal engineering, not optimization; this rule is about not transforming existing working code uninvited
- When performance IS the task: measure first, state what you measured, and optimize the measured bottleneck rather than everything in sight
- If you spot a probable real performance problem, report the evidence in a sentence or two ("this runs N queries in a loop; likely slow at scale, want it fixed?") and let the user decide

**Red flags that you're about to violate this:**
- "While I'm here, this could be much more efficient..."
- "A quick lru_cache makes this basically free..."
- "This does redundant work, I'll memoize it..."
- "Generators would avoid materializing this list..."
- "Two queries where one would do, easy optimization..."
- "It's strictly faster, so it can't be a regression..."

---

## Why It Works

1. **It reclassifies caching as a correctness decision.** The AI files caching under "free speed"; naming the staleness bet and invalidation risk moves it into the category of changes that need explicit consent.

2. **It demands a demonstrated problem.** "Could be more efficient" is true of nearly all code; requiring a named speed problem or measurement removes the universally available justification.

3. **It protects the legitimate path.** Sensible algorithm choice in new code stays allowed, so the rule can't be dismissed as demanding deliberately bad code; it targets uninvited transformations of working code.

4. **It refutes "strictly faster."** The claim ignores semantic shifts in evaluation order and failure behavior; listing those shifts as the actual price kills the "can't be a regression" syllogism.

## Origin

A fix to a permissions helper arrived with a bonus `lru_cache` on the lookup function, because the assistant noticed repeated calls. Permissions changes then took up to a process-lifetime to propagate: a revoked contractor's access kept working on whichever app servers had cached the old result. It surfaced in an access review, classified as a security incident. The original ticket had been about a typo in an error message.
