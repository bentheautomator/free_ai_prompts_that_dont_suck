---
title: Don't Plan Past the Next Unknown
slug: dont-plan-past-the-next-unknown
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "Ten detailed steps where steps 5-10 depend on what steps 1-4 will reveal"
---

# Don't Plan Past the Next Unknown

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents writing detailed plans for work whose shape depends on discoveries that haven't happened yet.

**[Copy-paste ready version](../../install/dont-plan-past-the-next-unknown.md)** — just the instruction block, no explanation.

## The Problem

Asked to plan an investigation-shaped task — "figure out why exports are slow and fix it" — the assistant produces ten detailed steps, of which steps 5 through 10 describe, in confident specificity, the fix for a cause that step 3 hasn't diagnosed yet. "Step 6: add an index on `created_at`. Step 7: batch the S3 uploads." These aren't plan steps; they're predictions cosplaying as steps. The plan's precision is uniform, but its knowledge isn't — everything past the diagnosis is fiction with formatting.

The harm isn't the wasted prose. It's that detailed fiction *binds*. Once "add the index" exists as step 6, the diagnosis in step 3 starts unconsciously auditioning evidence for the indexed-query theory; contradicting data gets less weight because contradicting data means rewriting half the plan. The speculative steps also burn review credibility — the user approves ten steps, of which six were never real, training everyone that plans are vibes. And when discovery inevitably rewrites the back half, the rewrite often happens silently, because the original was never marked as provisional in the first place.

The mature structure is the horizon plan: full detail up to the next major unknown, then an explicit decision point, then sketch. "Steps 1-3: instrument and diagnose. Decision point: plan the fix based on what we find — likely shapes are query, serialization, or upload." That plan is honest about where its knowledge ends — which is exactly the property that lets it stay authoritative all the way through.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Plan Past the Next Unknown

NEVER write detailed steps for work whose shape depends on a discovery you haven't made yet. Plan in full detail up to the next major unknown, mark an explicit decision point there, and keep everything beyond it as a sketch — clearly labeled as one.

The core problem: speculative steps written with the same precision as real ones bind the investigation to a predicted answer and train the user to treat plan detail as noise.

- Find the horizon: the first point where the right next steps depend on something you'll learn (a diagnosis, a measurement, an answer, a spike result). Detail stops there.
- At the horizon, write a decision point, not a guess: "Decision: choose fix based on profile results — candidate shapes: A, B, C." Candidates are fine; commitments are not.
- Past the horizon, sketch only what's plausibly invariant: "then implement the fix, add a regression test, verify against the original report."
- When you reach the decision point, actually stop and plan the next leg — out loud — using what was learned. This is where the user re-engages, with real information this time.
- If the task has no major unknowns, fine: plan it end to end. This rule is for tasks where discovery is a step, not a formality.

**Red flags that you're about to violate this:**
- "Step 6: implement the fix for the root cause" (which is identified in step 3)
- "Most likely it's the query, so the plan assumes that..."
- "A complete plan looks more thorough than one that stops halfway..."
- "I'll revise the later steps if the diagnosis surprises me..." (revise them, or quietly defend them?)
- "The user wants the full picture up front..." (they want a true picture)

---

## Why It Works

1. **It removes the anchor before it forms.** A written "step 6: add the index" makes the diagnosis a defense of the prediction; an open decision point keeps the diagnosis a question. The investigation stays evidence-driven only if no answer is on the books yet.

2. **It matches plan precision to actual knowledge.** Uniform detail over non-uniform certainty is misinformation. Detail-then-decision-point-then-sketch encodes exactly where knowledge ends, which is the single most useful thing a plan can communicate.

3. **It schedules re-planning instead of hoping for it.** The decision point makes "stop and plan the next leg" a step that's *on* the plan — so the mid-task reassessment happens by design, with the user present, rather than as a silent rewrite when the prediction collapses.

## Origin

A performance task arrived with a ten-step plan: steps 1-2 added instrumentation, steps 3-10 detailed the fix for what was "almost certainly N+1 queries in the serializer." The instrumentation in fact showed queries were fast and the time was in a synchronous image-resize call. The assistant, with eight pre-written steps facing falsification, spent another session optimizing the already-fast queries anyway — the plan said to. The image-resize fix, an afternoon's work, happened a week later, after a human read the profile output without a script in hand.
