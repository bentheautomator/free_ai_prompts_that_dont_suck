---
title: Keep the Plan Alive While Coding
slug: keep-the-plan-alive-while-coding
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "The plan written, praised, approved, and never consulted again"
---

# Keep the Plan Alive While Coding

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the plan from becoming a ceremonial document the moment the first edit lands.

**[Copy-paste ready version](../../install/keep-the-plan-alive-while-coding.md)** — just the instruction block, no explanation.

## The Problem

The assistant writes a good plan, gets it approved, and then enters coding mode — where the plan stops being an instrument and becomes a relic. Edits flow from whatever the current file suggests next. Steps are never checked off, never consulted, never compared against what's actually happening. Ask which step the current work belongs to and the honest answer is "none, exactly" — the work has been steering by local momentum for an hour while the plan sits upstream, pristine and increasingly fictional.

This isn't the same as abandoning the plan when a step gets hard. Nothing got hard. The plan just stopped *participating*: it shaped nothing after minute five, and the divergence between plan and work accumulated through a hundred small unconsulted choices rather than one dramatic pivot. The end state is familiar — a final diff that half-matches the approved plan, with no record of when or why each departure happened, and an ordering that ignored the sequencing the plan existed to provide.

The fix is to give the plan a runtime role, not just an approval role: a live checklist that work is attributed to, updated as steps complete, glanced at when transitioning. A plan consulted at every step boundary stays steering; a plan consulted never is a press release written in advance.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep the Plan Alive While Coding

ALWAYS execute against the plan, not merely after it. The plan is a runtime instrument: work gets attributed to a step, steps get marked done when verified, and the plan gets glanced at on every transition. A plan only consulted at approval time is a press release written in advance.

The core problem: coding mode steers by whatever the current file suggests next, so without forced contact, plan and work diverge through a hundred small unconsulted choices — none dramatic, all unrecorded.

- Keep the plan visible as a live checklist. As each step completes, mark it and say so: "Step 2 done (verified by X). Starting step 3."
- Before significant chunks of work, attribute them: which step is this? If the answer is "none," you're either off-plan (say so and update it) or doing work that needs its own line item.
- At each step boundary, reread the remaining steps for ten seconds. Steps written an hour ago, before everything you've since learned, deserve a quick freshness check.
- Update the plan when reality updates: steps that merged, split, became unnecessary, or appeared. The plan should describe the work as currently understood, always.
- At the end, reconcile: walk the final plan against what shipped. Leftover unmarked steps are either unfinished work or evidence the plan drifted unannounced — both worth saying.

**Red flags that you're about to violate this:**
- "The plan got me started, I've got it from here..."
- "I know what the steps were, no need to look..."
- "I'll mark everything done at the end..."
- "This bit of work doesn't map to a step, but it's clearly needed..." (then the plan needs a new line, out loud)
- "The plan is roughly what I'm doing..." (roughly?)

---

## Why It Works

1. **Attribution creates contact.** "Which step is this work?" is a question that physically cannot be answered without looking at the plan. Requiring the answer before each chunk forces the consultations that good intentions never schedule.

2. **Checked-off steps make drift observable.** When completion is marked in real time, a plan-versus-work divergence shows up as a step that's been "in progress" for an hour or work with no step at all — visible now, instead of reconstructed forensically from the final diff.

3. **The boundary reread exploits new information.** Each completed step teaches something the original plan didn't know. Ten seconds of rereading at each transition is the cheapest possible mechanism for letting those lessons revise the remaining steps before they're executed stale.

## Origin

An approved five-step plan for an auth refactor produced a final diff containing: steps 1 and 2 as planned, a step 3 that had silently become two different things, an unplanned middleware rewrite the plan never mentioned, and no step 5. None of it was a deliberate pivot — reviewing the session log showed the plan was simply never referenced again after the first edit, and each departure was a local next-thing that seemed obvious in the moment. The reviewer's question — "was the plan wrong, or just decorative?" — had no good answer, which was the answer.
