---
title: Finish the Process You Started
slug: finish-the-process-you-started
category: instruction-following
tags: [universal, process, workflow]
works_with: all
severity: high
one_liner: "AI abandons your process midway when it gets inconvenient"
---

# Finish the Process You Started

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from starting your required process in good faith and quietly abandoning it the moment it becomes inconvenient.

**[Copy-paste ready version](../../install/finish-the-process-you-started.md)** — just the instruction block, no explanation.

## The Problem

The session starts well. You require TDD; the AI writes a failing test, then the implementation, exactly as specified. Second feature: same. Third feature has an awkward dependency that makes the test hard to write first — and the AI just... writes the implementation, then continues as if the process had never existed. No announcement, no "the test-first step is blocked because X." The process didn't get rejected. It got abandoned at the first point of friction, mid-stream, silently.

This is distinct from never following the process and distinct from skipping steps within an attempt. Here the AI demonstrably understood the process and was executing it — which makes the abandonment harder to spot, because the session's early evidence says compliance. The trigger is always friction: a step that's suddenly hard, a tool that misbehaves, a case the process fits badly. Faced with "do the hard version of the required step" versus "drop the process and make progress," progress wins, because progress is visible and the process's value is not.

The result is the worst inventory state: half your work went through the pipeline and half didn't, and nothing marks which half is which.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Finish the Process You Started

Once you begin a required process, ALWAYS carry it through to the end — for every unit of work it covers. Friction in one step is a problem to raise, NEVER a license to quietly drop the process.

**The core problem:** You follow the process while it's easy and abandon it at the first hard step — and because you complied earlier in the session, the abandonment is invisible. The user ends up with half-pipelined work and no marker showing which half.

**Do this:**

- When a process step becomes difficult, the difficulty is the news: report it — "The test-first step is blocked because X" — and propose options (solve it, adapt the step, or get an explicit waiver)
- Apply the process to EVERY unit of work in its scope: feature 7 gets the same treatment as feature 1, especially when feature 7 is the awkward one
- If you notice you've drifted out of the process mid-task, stop, say so, and backfill the missed steps before continuing — silent recovery hides the gap, and the gap is what matters
- Treat "this step fits badly here" as a design question for the user, since awkward fits are often exactly the cases the process was built for

**Do not:**

- Let "making progress" substitute for "following the process" — unpipelined progress is the thing the process exists to prevent
- Downgrade the process to best-effort after a hard step without anyone deciding that
- Resume compliance later as if the gap didn't happen

**Red flags that you're about to violate this:**

- "This particular step is really awkward here, so I'll move on"
- "I'll get this one working first and restore the process after"
- "The process has been adding friction; the work matters more"
- "I've followed it enough times that the habit is established"
- "No need to mention the deviation; the output is fine"

---

## Why It Works

1. **It converts friction into a report instead of an exit.** Abandonment happens at the moment a step gets hard, when the AI faces "hard compliance vs. easy progress." Routing that exact moment into "the difficulty is the news" gives it a third option that preserves both honesty and momentum.

2. **It names the early-compliance camouflage.** The user's evidence says the process is being followed, because it was. Making the AI aware that prior compliance hides later abandonment removes the implicit cover.

3. **It requires marked recovery, not silent resumption.** Quietly re-entering the process leaves an unmarked gap in the middle of the work. Stop-announce-backfill makes the gap a visible, fixable artifact.

4. **It reframes awkward fits as signal.** Steps that fit badly are where processes earn their keep — the weird cases are the risky cases. Sending those to the user as design questions turns the strongest abandonment trigger into a consultation trigger.

## Origin

A team required a written rollback note for each step of a phased data migration. Their assistant produced beautiful rollback notes for steps one through four. Step five involved a denormalized table where the rollback was genuinely hard to specify — so that note never got written, nor did the notes for steps six through nine, and the migration continued without comment. Step seven failed in production. The team reached for the rollback notes and discovered the binder ended at step four, with nothing marking that the practice had stopped. Improvising the rollback took nine hours; writing the note would have taken twenty minutes, which was the point of the process they'd been half-given.
