---
title: Profile Before You Optimize
slug: profile-before-you-optimize
category: performance
tags: [universal, performance]
works_with: all
severity: medium
one_liner: "Stops optimization sprees aimed at code that was never the bottleneck"
---

# Profile Before You Optimize

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "optimizing" whatever code looks slow to it instead of measuring what is actually slow.

**[Copy-paste ready version](../../install/profile-before-you-optimize.md)** — just the instruction block, no explanation.

## The Problem

Tell an AI assistant "this endpoint is slow, make it faster" and it starts editing immediately. It picks targets by visual inspection: a nested loop here, a list comprehension there, a function call it can inline. Twenty minutes later you have a diff touching eight files, each change individually plausible, and an endpoint that is exactly as slow as before — because the actual time was going to one unindexed query or one serializer that ran per-row, and the AI never looked.

This happens because the AI optimizes what it can see in the diff context, not what the runtime spends time on. Code that *reads* slow (loops, recursion, string handling) attracts edits; code that *is* slow (I/O, allocation churn, a single pathological call) is invisible without a profiler or timing data. The result is the worst trade in software: real risk of new bugs in exchange for zero measured improvement.

The fix is mechanical, not philosophical. No measurement, no optimization. A profile, a flame graph, an `EXPLAIN ANALYZE`, or even three timestamped log lines beats any amount of squinting at source code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Profile Before You Optimize

NEVER start optimizing until you have measurement data identifying where time is actually spent. Code that looks slow and code that is slow are usually different code.

When asked to make something faster:

- First obtain or produce a measurement: a profiler run, flame graph, `EXPLAIN ANALYZE`, request timing breakdown, or at minimum timestamped logging around the suspected sections. Ask the user for existing profiles or APM data before instrumenting by hand.
- Identify the top one or two contributors by measured time. Optimize those. Ignore everything below them, no matter how ugly it looks.
- If you cannot run a profiler in this environment, say so, add the timing instrumentation, and ask the user to run it — do not substitute guessing for measuring.
- State your finding before editing: "X% of the time is in Y, so I'm changing Y." If you can't fill in that sentence with a number, you're not ready to edit.
- Do not bundle drive-by "while I'm here" optimizations of unmeasured code into the change.

**Red flags that you're about to violate this:**
- "This nested loop is obviously the bottleneck."
- "I can see several inefficiencies, let me clean them all up."
- "Profiling would take time; the problem is clear from reading the code."
- "Even if this isn't the main cost, it can't hurt to optimize it."
- "The user said it's slow, so I'll make everything faster."

---

## Why It Works

1. **It forces a number into the workflow.** "Optimize" is open-ended; "name the top contributor by measured time" has a verifiable answer, and the AI cannot fake it without producing data.
2. **It names the visual-inspection trap.** The AI's strongest instinct — nested loop equals slow — is called out explicitly as the thing that is usually wrong, which interrupts the pattern-match.
3. **It provides the fallback path.** AIs skip profiling because they often can't execute code; giving them "instrument and hand back to the user" removes the excuse for guessing.
4. **It bans the shotgun diff.** Limiting edits to measured contributors keeps the change reviewable and keeps risk proportional to evidence.

## Origin

A team asked their assistant to speed up a report generation endpoint that took 40 seconds. The AI rewrote the aggregation logic, replaced dicts with arrays, and inlined helpers across six files. The endpoint still took 39 seconds: 95% of the time was a single query fetching an unfiltered join, visible in the very first profile anyone ran — a week later, while debugging a regression one of the "optimizations" had introduced.
