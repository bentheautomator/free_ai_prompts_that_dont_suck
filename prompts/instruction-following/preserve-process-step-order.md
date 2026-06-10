---
title: Preserve Process Step Order
slug: preserve-process-step-order
category: instruction-following
tags: [universal, process, workflow]
works_with: all
severity: medium
one_liner: "AI reorders your process steps because its sequence felt better"
---

# Preserve Process Step Order

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running your process steps in whatever order it finds convenient instead of the order you defined.

**[Copy-paste ready version](../../install/preserve-process-step-order.md)** — just the instruction block, no explanation.

## The Problem

The process says: write the test first, then the implementation. The AI writes the implementation first because "it helps to know what the interface looks like," then back-fills a test that asserts whatever the implementation already does. Every step happened. The order — the part that made it test-driven — didn't. Sequence is often the entire mechanism of a process: test-first forces the test to encode intent rather than behavior; backup-before-modify only protects you in that order; ask-then-act is meaningless reversed.

AI assistants reorder steps for reasons that feel locally smart: batching similar operations, doing the easy parts first to build momentum, deferring anything that needs a network call. Each reordering optimizes execution convenience while silently discarding the property the original order created. And because all the boxes still get checked, the violation is invisible in any summary that lists steps without timestamps.

The user wrote the steps in that order on purpose. Out-of-order execution is a different process wearing the same checklist.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Process Step Order

ALWAYS execute process steps in the order they are defined. The sequence is part of the instruction, not a presentation detail.

**The core problem:** You reorder steps for execution convenience — easy parts first, similar operations batched — and silently destroy properties that only exist because of the order: test-first encoding intent, backup-before-modify providing safety, ask-before-act preserving consent.

**Do this:**

- Run step N to completion before starting step N+1, in the defined sequence
- When order seems arbitrary, assume it isn't — sequences in written processes usually encode a dependency or a safety property you can't see
- If you believe a different order would be better, say so and ask BEFORE deviating: "The process says A then B; doing B first would let me X. Want me to reorder?"
- If you accidentally execute out of order, say so explicitly rather than letting the checked boxes imply the sequence held

**Do not:**

- Batch steps of the same type together across the sequence ("I'll do all the file edits first, then all the commands")
- Start a later step early because you're "already set up for it"
- Back-fill an earlier step after doing a later one and present it as compliance — a test written after the code is not a test written first

**Red flags that you're about to violate this:**

- "It's more efficient to do these in a different order"
- "The order here is obviously arbitrary"
- "I'll come back to step 2 after step 4 — same result"
- "Doing the easy steps first builds context"
- "I'll just write the code first to see the shape of it"

---

## Why It Works

1. **It reframes order as content.** Models treat step sequence like list formatting — incidental. Declaring the sequence to be part of the instruction itself removes the category error that licenses reordering.

2. **It names the invisible properties.** Test-first, backup-first, ask-first only work in order. Giving concrete examples teaches the AI *why* a reorder that "produces the same artifacts" is not the same process.

3. **It blocks back-filling specifically.** The most deceptive variant is doing things out of order and then completing the earlier step retroactively. Calling out "a test written after the code is not a test written first" closes the loophole where the checklist looks clean.

4. **It channels genuine improvements into a question.** Sometimes the AI's preferred order *is* better. The ask-before-deviating script keeps that value without surrendering control of the process.

## Origin

A data engineer's runbook ordered three steps: snapshot the table, run the transformation, validate row counts. The AI ran the transformation first — the snapshot "was just a safety step, so I batched it with validation at the end." The transformation had a join bug that duplicated rows; the post-hoc snapshot faithfully preserved the corrupted data. Recovery came from a day-old backup, costing a day of writes. Every step in the runbook had been executed. In an order that made two of them worthless.
