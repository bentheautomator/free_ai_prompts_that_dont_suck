---
title: Verify Green Between Refactoring Steps
slug: verify-green-between-refactoring-steps
category: refactoring
tags: [universal, refactoring, testing]
works_with: all
severity: high
one_liner: "Stops batches of unverified refactoring steps with one hopeful check at the end"
---

# Verify Green Between Refactoring Steps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from applying a stack of refactoring steps with no verification until the end, when failures can no longer be attributed to a step.

**[Copy-paste ready version](../../install/verify-green-between-refactoring-steps.md)** — just the instruction block, no explanation.

## The Problem

Even an assistant that plans a refactor as nice small steps will often *execute* them as one batch: extract, rename, move, inline, restructure, and then, at the very end, run the tests once. When that single run fails, the diagnostic value of the small steps is gone. The failure could live in any of six transformations, the working tree is a compound of all of them, and the model's typical recovery is to start "fixing" the end state, which adds a seventh unverified change to the pile. The whole point of stepwise refactoring was that each step is checkable, and batch execution quietly deletes that property while keeping the appearance of discipline.

Models batch because verification is friction: running tests produces no new code, and the model's reward gradient points toward producing code. There's also misplaced confidence; each step *seems* obviously correct as it's made, so checking feels redundant. It's redundant right up until it isn't, and by then the evidence of which step broke is buried.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Green Between Refactoring Steps

Refactor green-to-green: run the relevant tests (or at minimum build/typecheck) after EVERY refactoring step, before starting the next one. NEVER stack a second transformation on top of an unverified first.

A failure after one step indicts that step. A failure after six indicts the afternoon.

- The loop is fixed: apply one transformation, run the checks, confirm green, then proceed. The checkpoint is part of the step, not an optional epilogue.
- Use the fastest sufficient check between steps: the module's test file, the typechecker, the build. Run the broader suite at natural milestones and at the end. Speed objections are answered by choosing a faster check, not by skipping the checkpoint.
- If a checkpoint fails, fix or revert THAT step before doing anything else. Do not continue the plan on a red base, and do not fix the failure by starting the next transformation early ("step 4 will resolve this anyway").
- Red-to-red transitions are the trap: when checks were already failing before you started, record the exact pre-existing failures first, and hold every step to "no new failures" against that baseline.
- Commit or snapshot at green points when the environment allows; a known-good state to retreat to converts a bad step from surgery into an undo.
- If you notice you've made several edits without checking, stop and check now, before any further edits. The discipline recovers; the batch doesn't.

**Red flags that you're about to violate this:**

- "These next three steps are trivial; I'll test after all of them."
- "Running the suite between every step is too slow."
- "I'm confident in this change; checking would be a formality."
- "The code won't compile until step 4 anyway, so checks can wait."
- "I'll do one careful review of everything at the end instead."

---

## Why It Works

1. **It attaches verification to the step, not the task.** Models treat tests as a deliverable-gate at the end; redefining the checkpoint as the final act *of each step* makes skipping it feel like an incomplete step rather than deferred diligence.
2. **It prices the alternative in attribution, not virtue.** "One step indicts that step; six indict the afternoon" gives the model the actual engineering reason, so the rule reads as leverage rather than ceremony.
3. **The fastest-sufficient-check clause removes the honest objection.** Slow suites are the real-world excuse for batching; explicitly authorizing cheap intermediate checks (typecheck, one test file) takes the excuse off the table.
4. **The "won't compile until step 4" red flag targets plan-smell.** A plan with mandatory broken intermediate states isn't small steps at all; flagging that thought forces re-decomposition instead of checkpoint suspension.

## Origin

An assistant executed a six-step restructuring of a permissions module in one continuous burst, then ran the tests: eleven failures. Unable to tell which transformation broke authorization checks, it began patching the combined result, and the patches introduced a bypass that the original code didn't have. The eventual fix was a full revert and a redo with checks between steps; the redo found the bad step (a botched extract) in its second checkpoint, eight minutes in.
