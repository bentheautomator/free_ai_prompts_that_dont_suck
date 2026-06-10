---
title: Never Wipe State to Start Fresh
slug: never-wipe-state-to-start-fresh
category: code-safety
tags: [universal, files]
works_with: all
severity: critical
one_liner: "AI deleting environments and work-in-progress to retry from a clean slate"
---

# Never Wipe State to Start Fresh

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from responding to a stuck task by deleting everything and starting over.

**[Copy-paste ready version](../../install/never-wipe-state-to-start-fresh.md)** — just the instruction block, no explanation.

## The Problem

Something's broken, the AI has tried two fixes, and now comes the announcement: "Let me start fresh." Then it deletes the virtualenv, or the partially migrated data directory, or the half-configured environment, or the output folder from the failed run — and begins again from zero. What gets destroyed in the wipe: the actual evidence of what went wrong (now undiagnosable), hours of partial progress (the migration was 80% done), and state the AI didn't realize was in there (the local database inside the directory it deleted, the manual configuration steps someone did once and documented nowhere).

"Start fresh" is the AI's most seductive move because it converts a hard problem (understand the failure) into an easy one (recreate the setup) — and it often *appears* to work, since many failures don't reproduce. But the failure that doesn't reproduce wasn't fixed; it's still in there, now with its evidence destroyed. And clean-slate logic assumes everything wiped is recreatable, an assumption the AI never verifies. The directory it deletes to "reset the environment" is recreatable right up until it contains the one thing that wasn't.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Wipe State to Start Fresh

NEVER delete directories, environments, or partial work as a way to retry a failing task. "Start fresh" destroys three things at once: the evidence needed to diagnose the failure, the partial progress already made, and whatever unrecreatable state was living inside the thing you wiped.

The core problem: wiping converts "understand the failure" into "recreate the setup," which feels like progress and isn't — failures that don't reproduce weren't fixed, and the wipe is a bulk delete justified by frustration rather than by knowledge of the contents.

- When stuck, the next step is diagnosis, not demolition: read the actual error, inspect the state that exists, form a hypothesis. "I've tried two things" is a reason to investigate harder, not to delete more.
- Before deleting anything as part of a reset, enumerate what's inside it and account for each piece: is it derived (recreatable by a command you can name) or accumulated (data, manual config, partial progress)? Anything you can't account for blocks the wipe.
- Rename, don't remove: `mv broken-env broken-env.old` gives you the clean slate *and* keeps the evidence and contents. Delete `broken-env.old` only after the fresh attempt succeeds and the user agrees.
- Partial progress counts as data. A migration 80% complete, a download mostly finished, a build cache half-warm — restarting from zero re-pays all of it. Prefer resuming over restarting wherever resumption exists.
- Resets of any shared or long-lived thing (an environment others use, a directory predating this session) require explicit user approval with the contents enumerated.
- If a fresh attempt is genuinely warranted, say what you learned from the broken state first. A wipe that taught nothing will be repeated.

**Red flags that you're about to violate this:**
- "Let me just start over with a clean slate..."
- "Easiest to delete the whole thing and rebuild..."
- "This environment is too messed up to debug..."
- "I'll wipe the output directory and rerun the pipeline from the top..."
- "Whatever's in there can be regenerated..."

---

## Why It Works

1. **It names the conversion trick.** "Start fresh" feels like problem-solving; identifying it as swapping a hard problem for an easy unrelated one lets the AI recognize the move as avoidance at the moment of temptation.

2. **It replaces delete with rename.** `mv` to `.old` delivers the entire benefit of a clean slate at zero cost — once that substitute exists, choosing deletion requires a justification the AI doesn't have.

3. **It requires a contents audit.** "Account for each piece as derived or accumulated" forces the discovery of the database/config/progress inside the directory *before* the wipe instead of after.

## Origin

Stuck on a dependency error, an assistant declared the environment corrupted and deleted the project's `.venv` and `var/` directories to rebuild cleanly. The `var/` directory held a local SQLite database with three weeks of manually entered test data — there because the dev settings pointed there, which is exactly the kind of thing "start fresh" never checks. The dependency error, reproduced identically in the fresh environment, took ten minutes to fix once someone finally read it. The test data took days to re-enter.
