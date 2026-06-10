---
title: Don't Redo Completed Task Steps
slug: dont-redo-completed-task-steps
category: agents-and-automation
tags: [universal, agents, context]
works_with: all
severity: medium
one_liner: "Re-running migrations and reinstalls the session already finished"
---

# Don't Redo Completed Task Steps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from repeating steps it already completed — reinstalling, re-migrating, re-editing — because it lost track of what's done.

**[Copy-paste ready version](../../install/dont-redo-completed-task-steps.md)** — just the instruction block, no explanation.

## The Problem

Deep into a long session, the agent runs `npm install` for the third time. Then it re-applies a code change to a file — a change that's already there, producing a duplicated block. Then it re-runs a database migration that already ran, which fails, which sends it off debugging a "migration error" that is actually just the echo of its own earlier success. Each redo costs tokens and minutes; the non-idempotent ones (duplicate inserts, doubled config lines, re-applied patches) cost correctness too.

This is what task execution looks like when the record of completion lives only in the agent's attention. After enough intervening steps — or a compaction — "did I already do this?" has no reliable answer, and agents resolve that uncertainty by doing, because doing feels safe and checking feels like a digression. But re-doing is only safe for idempotent operations, and the agent rarely distinguishes. The duplicated edit is the classic tell: a function body appearing twice in a file, signed by an agent that forgot its own handwriting.

The fix isn't memory — memory is exactly what long sessions can't guarantee. The fix is treating the workspace as the record: completed steps leave evidence, and evidence beats recollection.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Redo Completed Task Steps

NEVER repeat a step because you can't remember whether you did it. Check the workspace for evidence instead — completed steps leave traces, and the trace is more reliable than your recollection.

The core problem: in long sessions, "did I already do this?" eventually has no confident answer from memory, and resolving uncertainty by re-doing is only safe for idempotent operations. Many operations aren't.

- Before re-running setup or state-changing steps, look for their evidence: `node_modules` exists and the lockfile is unchanged means installed; the migrations table shows the migration ran; the branch exists; the package is in the manifest. Ten seconds of checking beats two minutes of re-running and beats hours of debugging a double-application.
- Before re-applying an edit, read the target region first. If the change is already present, the step is done — do not paste it again. Duplicated blocks in a file are the signature of this failure.
- Maintain a done-list as you work: one line per completed step, in your task tracker or notes file ("step 3 DONE: migration 0042 applied"). Future-you, post-compaction, will trust this list over a vague sense of déjà vu.
- Be most careful with non-idempotent steps: data insertions, migrations, appends to files, sending notifications, anything that says "add." For these, absence of certainty means CHECK, never re-run.
- If you catch one redo, audit briefly for others — losing track is a state, not an event, and the third `npm install` rarely travels alone.
- After a compaction or summary, assume your sense of progress is unreliable: re-derive the done-list from workspace evidence and your notes before taking the next action.

**Red flags that you're about to violate this:**
- "Let me just run the install again to be sure..."
- "I'll re-apply that change in case it didn't take..."
- "Running it twice can't hurt..." (for migrations and appends, it can)
- "I don't remember doing this step, so I probably didn't..."
- "Better safe than sorry, I'll do it again..."

---

## Why It Works

1. **It replaces recall with evidence.** The failure stems from trusting memory in sessions designed to exceed memory. Redirecting "did I do this?" to workspace traces makes the answer cheap, reliable, and available even after compaction.

2. **It splits the world by idempotency.** "Re-running can't hurt" is true for `ls` and false for migrations. Forcing the distinction at the moment of uncertainty contains the damage to the harmless cases.

3. **It makes the done-list a durable artifact.** A one-line-per-step log costs almost nothing and converts the worst case (post-compaction amnesia) into a lookup instead of a guessing game.

4. **It treats one redo as a symptom.** Lost tracking is systemic; the prompt's audit instruction catches the other redos before they execute.

## Origin

A long data-import session re-ran its "seed reference tables" step after a context compaction blurred its progress. The seed script used plain inserts, not upserts; every reference row was now duplicated, and the import's foreign-key lookups started returning two matches. The agent spent the rest of its budget investigating a "data integrity bug" it had created twenty minutes earlier — and its own transcript, just above the compaction line, showed the step completing successfully the first time.
