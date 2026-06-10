---
title: Break Work Into Reviewable Steps
slug: break-work-into-reviewable-steps
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "The 40-file mega-diff that nobody can review and nobody can revert"
---

# Break Work Into Reviewable Steps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a large task from being delivered as one undifferentiated blob of changes that can only be accepted or rejected whole.

**[Copy-paste ready version](../../install/break-work-into-reviewable-steps.md)** — just the instruction block, no explanation.

## The Problem

Give an AI assistant a large task — "migrate the app from REST polling to websockets" — and it will happily produce one continuous avalanche of edits: forty files, two thousand lines, transport code interleaved with refactors interleaved with renames it did "while it was in there." Each individual edit may be fine. The aggregate is unreviewable. You can't tell which changes are the migration and which are incidental, you can't verify the halfway state, and when one piece is wrong your only options are forensic archaeology or full revert.

Assistants do this because they don't experience review cost. To the model, emitting two thousand lines is the same motion as emitting fifty; the pain lands entirely on the human who has to verify it. There's no internal pressure to find seams, so the work gets sliced by what the assistant encountered next, not by what a reviewer could check.

The fix isn't "do less." It's structuring the same work as a sequence of steps where each step is independently understandable, independently testable, and small enough that a human can actually hold it in their head.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Break Work Into Reviewable Steps

ALWAYS decompose a task that touches more than a handful of files into discrete steps, where each step is independently reviewable: a human can read it, understand what it does, and check that it's correct without reading the other steps.

The core problem: you don't feel review cost, so without a rule you'll slice work by what you encountered next instead of by what a reviewer can verify.

- Before starting a large task, propose the step breakdown: 3-7 steps, each with a one-line description of what it changes and how to verify it.
- A good step boundary leaves the codebase in a working state. "Add the new code path behind a flag," "switch callers over," "delete the old path" are three steps, not one.
- Keep mechanical changes (renames, moves, formatting) in separate steps from behavioral changes. A reviewer can skim a pure rename; they cannot skim a rename with logic edits hidden inside it.
- Finish and verify each step before starting the next. Announce step transitions so the user can review incrementally instead of facing everything at the end.
- If a step grows past what you estimated — it's touching triple the files you said — stop and split it rather than letting it swallow the plan.
- Don't fold opportunistic improvements into a step. If you spot something worth fixing, note it as a candidate future step.

**Red flags that you're about to violate this:**
- "While I'm in this file anyway, I'll also..."
- "It's all one logical change really, splitting it is artificial..."
- "I'll do everything and they can review the final diff..."
- "Pausing between steps just adds overhead..."
- "This rename is trivial, I'll mix it in with the logic change..."

---

## Why It Works

1. **It defines reviewable instead of assuming it.** "Independently understandable, testable, and small" gives the assistant an actual test for step boundaries; without a definition, "step" degrades into "paragraph break in my narration."

2. **It exploits the working-state checkpoint.** Steps that leave the build green are revertable and bisectable. That property — not step count — is what makes incremental delivery valuable, so the rule names it directly.

3. **It separates mechanical from behavioral noise.** The single biggest reviewability killer is logic hidden in a rename diff. Forcing the split makes the dangerous 5% of lines visible instead of camouflaged in the harmless 95%.

4. **It catches step inflation early.** Steps don't fail by being skipped; they fail by quietly tripling. The "stop and split when it exceeds the estimate" trigger converts inflation into a visible event.

## Origin

A team asked their assistant to swap a homegrown date library for a standard one. The result was a single 3,400-line diff: the swap, plus reformatted imports in every touched file, plus a few "obvious" logic cleanups in date arithmetic. One of those cleanups inverted a timezone offset. It took two engineers most of a day to find it, because the meaningful 30 lines were distributed through 3,400 mechanical ones. Done as four steps, the bad cleanup would have been a ten-minute review in a 60-line diff.
