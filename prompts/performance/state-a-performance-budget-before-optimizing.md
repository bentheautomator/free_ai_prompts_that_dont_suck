---
title: State a Performance Budget Before Optimizing
slug: state-a-performance-budget-before-optimizing
category: performance
tags: [universal, performance]
works_with: all
severity: medium
one_liner: "Stops open-ended optimization with no target, no baseline, and no finish line"
---

# State a Performance Budget Before Optimizing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from starting performance work without a numeric target, which makes every change justifiable and none of them finishable.

**[Copy-paste ready version](../../install/state-a-performance-budget-before-optimizing.md)** — just the instruction block, no explanation.

## The Problem

"Make it faster" has no stopping condition. Given that brief, an AI assistant will keep finding things to change indefinitely, because without a target every micro-improvement is justified and no amount of speed is enough. The result is open-ended churn: caching added here, a clever rewrite there, each PR claiming "improved performance" with no number attached, no baseline to compare against, and no way to say "done." Optimization without a budget isn't engineering; it's a hobby with a burn rate.

The inverse failure is just as common: the endpoint takes 180ms, the team's actual requirement is 500ms, and the assistant spends a day of complexity getting to 90ms — a 2x improvement of something that was already fine. Nobody asked "fast compared to what?" so the work had no way to be unnecessary.

Budgets also change *which* optimizations are right. Getting from 4s to 1s is usually one algorithmic fix; getting from 120ms to 50ms might mean caching and denormalization; getting from 20ms to 5ms is a different sport entirely. Without the target, the assistant can't pick the right class of change, so it picks all of them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### State a Performance Budget Before Optimizing

NEVER begin performance work without three numbers written down: the current measurement (baseline), the target (budget), and the conditions under which both are measured. "Faster" is not a requirement; "p95 under 300ms at 200 rps on production-shaped data" is.

Without a target, every change is justifiable and none are finishable; with one, work has a direction and a stopping point.

- If the user asks for "faster" without a number, ask for one (or propose one from context: SLO, timeout, page-load guidance, job-window deadline) and get agreement before changing code.
- Record the baseline first, under stated conditions: percentile, load level, dataset size, environment. An optimization without a baseline can't prove it did anything.
- Pick changes appropriate to the gap. A 10x gap means an algorithmic or I/O-pattern problem; chasing micro-optimizations against a 10x gap is effort misallocation. A 1.2x gap might need only one targeted fix.
- Stop when the budget is met. Meeting the target and continuing to optimize is scope creep with extra risk; bank the win and move on.
- Report results against the budget: "baseline 1.8s, target 500ms, now 340ms under the same conditions" — not "significantly improved performance."
- If the budget is already met before any work starts, say so and recommend doing nothing. That is a valid and frequently correct deliverable.

**Red flags that you're about to violate this:**
- "I'll just make it as fast as possible."
- "No target was given, so any improvement is a win."
- "We're at 180ms, getting to 90ms can only help."
- "I'll measure the baseline after I finish the changes."
- "Performance work is never really done."
- "It feels faster."

---

## Why It Works

1. **It installs a stopping condition.** The AI's failure is unbounded justification; a numeric budget converts "is this change good?" into "does this close the gap?", which can be answered no.
2. **It legitimizes doing nothing.** Explicitly blessing "already under budget, recommend no work" gives the AI a way to win without producing diffs, which is otherwise against its instincts.
3. **It sizes the intervention to the gap.** Mapping gap magnitude to change class (10x means algorithmic, 1.2x means targeted) steers effort allocation before any code is touched.
4. **It makes claims falsifiable.** Requiring baseline, target, and conditions in the report turns "improved performance" from vibes into an auditable before/after under fixed measurement rules.

## Origin

A team's standing instruction to their assistant was "always keep performance in mind," and over a quarter their codebase accumulated eleven caching layers, three bespoke data structures, and a custom serializer, across PRs that each claimed speed wins with no baselines. When latency *actually* became a problem, nobody could say what the endpoint's budget was or which of the eleven caches mattered. The fix started with one sentence in the SLO doc — "p95 under 400ms at peak" — after which two caches stayed, nine were deleted, and p95 improved, because half the cleverness had been fighting the other half.
