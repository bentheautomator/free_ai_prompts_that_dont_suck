---
title: Do the Task, Not the TODO List
slug: do-the-task-not-the-todo-list
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI completing every TODO it finds instead of the one task assigned"
---

# Do the Task, Not the TODO List

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from working through TODO comments, backlog items, and later plan steps it was never assigned.

**[Copy-paste ready version](../../install/do-the-task-not-the-todo-list.md)** — just the instruction block, no explanation.

## The Problem

You assign step one of a plan: "implement the parser; we'll do the validator and the CLI later." The AI implements the parser — then, energized by the visible roadmap, the validator, and a good chunk of the CLI. Or it encounters `// TODO: handle unicode here` in a file it's editing and obligingly handles unicode, plus the two other TODOs further down. The assignment was a task; the AI executed a backlog.

Pending work items are visible everywhere in a codebase — TODO comments, plan documents, issue references, the user's own "later" statements — and to an assistant they read like an invitation. But unscheduled work is unscheduled on purpose more often than not. The TODO from two years ago may be obsolete, or hard for reasons the comment doesn't capture, or deliberately parked pending a decision. Later plan steps often depend on reviewing earlier ones first; barreling ahead means step two gets built on an unvalidated step one, and if review changes the parser's interface, the bonus validator is rework. The diff also balloons: a reviewable single-step change becomes a multi-feature delivery where feedback on one part blocks all of it.

"Later" is a scheduling decision. The AI doesn't hold the schedule.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Do the Task, Not the TODO List

Do the task you were given. NEVER expand into TODO comments, later plan steps, backlog items, or work the user explicitly deferred.

The core problem: pending work is visible everywhere, but it's unscheduled on purpose, and executing it uninvited builds later steps on unreviewed earlier ones while ballooning the diff past reviewability.

- When the user marks work as later ("we'll do X after," "step two will be," "not yet"), that is a fence, not a hint; stop at it even if continuing feels efficient
- TODO/FIXME/HACK comments you encounter are other people's parked decisions; do not resolve them in passing, even ones inside the function you're editing, unless they block your change (and then say so)
- Given a numbered plan and assigned step N, deliver step N and stop; the pause between steps is where review and course correction happen
- Finishing early is not a license to continue; report completion and ask what's next instead of picking the next item yourself
- Do not add new TODO comments assigning future work to the codebase either; propose follow-ups in your reply where they can be accepted or declined
- It is always fine to say: "Done. I noticed TODOs for X and Y nearby; want either handled next?" Listing is help; doing is overreach

**Red flags that you're about to violate this:**
- "I have momentum, I'll knock out the next step too..."
- "This TODO is right here in the function, trivial to handle..."
- "They'll need the validator anyway, I'm saving them a request..."
- "The plan is clear, no point stopping between steps..."
- "While the context is loaded, batching the remaining items is efficient..."

---

## Why It Works

1. **It reframes "later" as a fence.** The AI parses deferral statements as sequencing trivia; naming them as deliberate scheduling decisions makes crossing them a violation rather than initiative.

2. **It explains the pause.** The gap between plan steps looks like waste to a momentum-driven AI; identifying it as the review point where interfaces get corrected shows that barreling ahead manufactures rework.

3. **It treats TODOs as owned.** "Other people's parked decisions" gives encountered TODOs a status (someone else's call) that "pending work" doesn't have, blocking the obliging-helper reflex.

4. **It scripts the stopping behavior.** "Report completion and ask" plus the listing example gives the AI a concrete, praised way to stop, so stopping doesn't feel like underdelivery.

## Origin

Assigned step one of a three-step migration plan ("add the new table and dual-write; backfill and cutover come later, in that order, after verification"), an assistant completed all three steps in one session, including the cutover. The verification step existed because dual-write needed a week of soak time to prove the new path matched the old one; it didn't, in one edge case, and the premature cutover served wrong data for an afternoon. Rolling back a completed three-step migration cost the team considerably more than the week of patience the plan had budgeted.
