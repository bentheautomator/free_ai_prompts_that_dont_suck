---
title: Checkpoint Between Irreversible Steps
slug: checkpoint-between-irreversible-steps
category: planning
tags: [universal, planning, safety]
works_with: all
severity: high
one_liner: "Chaining irreversible operations with no verification between them"
---

# Checkpoint Between Irreversible Steps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents executing a sequence of irreversible operations back-to-back without verifying state between them.

**[Copy-paste ready version](../../install/checkpoint-between-irreversible-steps.md)** — just the instruction block, no explanation.

## The Problem

A plan contains three irreversible operations: migrate the data to the new table, drop the old table, delete the migration scaffolding. The assistant, in execution mode, runs them as a sequence — step, step, step — with nothing between but the assumption that each one worked. If the migration silently skipped rows (a type mismatch, a filtered subquery, a timeout), that fact was discoverable for exactly one window: after the migrate, before the drop. The plan scheduled nothing in that window. The drop closes it forever.

Assistants chain irreversible steps because plans read as linear scripts: each line follows the last, and "verify" isn't a line unless someone wrote it. Execution momentum does the rest — after step N succeeds (meaning: didn't error), step N+1 starts immediately. But "didn't error" and "did what we needed" are different claims, and the gap between them is precisely what gets laundered by momentum. With reversible steps, conflating them costs a fix-forward. With irreversible ones, it costs whatever just became unrecoverable.

The rule is structural: every irreversible operation gets a verification gate before the *next* irreversible operation. The gate checks the actual outcome — row counts match, the service answers on the new path, the backup restores — not the exit code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Checkpoint Between Irreversible Steps

NEVER run two irreversible operations back-to-back without verifying actual outcomes in between. "The command didn't error" is not verification; it's the absence of one kind of bad news.

The core problem: plans execute as linear scripts and momentum carries step N's apparent success straight into step N+1 — closing forever the only window in which step N's silent failure was discoverable.

- When planning, mark each step that can't be undone: dropping/truncating data, deleting files or branches, force-pushes, sending external messages, releasing versions, expiring credentials.
- Between any two marked steps, insert an explicit verification of the first one's *outcome*: counts compared, data spot-checked, the new path serving real traffic, the backup actually restored once.
- Pause at the gate. For high-stakes irreversibles, the gate is also where the user confirms — present the evidence ("row counts match: 1,482,003 both sides") and wait.
- Prefer plans that delay irreversibility: rename instead of drop, disable instead of delete, archive then remove later. Every irreversible step you convert to a reversible one deletes a gate you need.
- If verification at a gate fails, you are now glad to be standing still. Diagnose before anything else runs.

**Red flags that you're about to violate this:**
- "The migration ran clean, dropping the old table now..."
- "I'll run all three steps and verify at the end..." (the end is too late by definition)
- "Verification between steps is just ceremony, the commands are simple..."
- "Exit code zero, moving on..."
- "We can always restore from somewhere if needed..." (from where, exactly? checked when?)

---

## Why It Works

1. **It schedules discovery inside the only window it can happen.** A silent failure in an irreversible step is detectable only between that step and the next one. The gate is not extra caution — it's the sole position on the timeline where caution functions.

2. **It splits "didn't error" from "did the job."** Commands report their own mechanics, not your intent. Requiring outcome evidence (counts, reads, restores) closes the gap that exit codes launder.

3. **It rewards de-fanging the plan.** Rename-instead-of-drop turns an irreversible step reversible, which is strictly better than gating it. The rule creates pressure toward plans that need fewer gates at all.

## Origin

A cleanup task: archive a deprecated service's data to cold storage, then delete the live bucket. Both commands ran without error, in immediate succession. The archive job, it later emerged, had hit a permissions boundary partway through and uploaded 60% of the objects — a fact its exit code did not consider worth a nonzero status, but its logs stated plainly. The one moment those logs could have mattered was between the two commands. Verified-then-delete would have cost five minutes; the 40% cost a subpoena-response scramble eight months later.
