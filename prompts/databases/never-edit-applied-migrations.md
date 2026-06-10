---
title: Never Edit Applied Migrations
slug: never-edit-applied-migrations
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "Editing an already-applied migration file instead of writing a new one"
---

# Never Edit Applied Migrations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from modifying a migration that has already run, silently desyncing every database that applied the original version.

**[Copy-paste ready version](../../install/never-edit-applied-migrations.md)** — just the instruction block, no explanation.

## The Problem

You tell the AI "the `email` column should have been varchar(320), not varchar(100)." It finds the migration that created the column, changes `100` to `320` in place, and reports success. The file looks right now. But that migration already ran in staging, in prod, and on every teammate's laptop. Those databases recorded the migration as applied and will never run it again. The file now lies about what the schema actually is, and the real fix never happens anywhere.

AI assistants do this because editing the original file is the smallest possible diff. From a pure code-editing perspective, fixing the source of the mistake is correct. But a migration is not source code in the normal sense; it's a log entry. Once applied anywhere outside your own working copy, its contents are history, and history edits don't propagate. The migration framework tracks applied migrations by name or version, not by content hash, so nothing even warns you.

The damage shows up later and diffusely: a fresh database built from migrations doesn't match prod, a new hire's local schema differs from everyone else's, or a CI run passes against a schema prod doesn't have. Debugging schema drift caused by a silently edited migration is miserable precisely because the files all claim everything is fine.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Edit Applied Migrations

NEVER modify a migration file that may have already been applied to any database (prod, staging, CI, or a teammate's machine). Write a new migration instead.

A migration is an append-only log, not editable source code. Databases track migrations as applied by name/version and will never re-run an edited file, so your edit changes nothing except making the file lie about history.

- To fix a mistake in a previous migration, create a new migration that alters the schema to the corrected state (`ALTER TABLE users ALTER COLUMN email TYPE varchar(320)`), even if the original migration is "obviously wrong."
- Treat a migration as applied unless proven otherwise. Committed and pushed means applied. Merged means applied. Only a migration created in the current working session, never run outside this machine, is safely editable.
- This includes "harmless" edits: renaming the file, reformatting, changing a default, fixing a typo in a column name. Any content change to an applied migration is a violation.
- If asked directly to "fix the migration," say that it has already been applied and propose a corrective follow-up migration instead.
- Exception requires explicit human confirmation that the migration has never run anywhere, including CI.

**Red flags that you're about to violate this:**

- "It's cleaner to fix the mistake at its source..."
- "This migration is only a week old, it probably hasn't run anywhere..."
- "I'll just correct the typo in the original file..."
- "Editing it keeps the migration history tidy..."
- "The user said fix the migration, so they must mean this file..."

---

## Why It Works

1. **It reframes migrations as a log, not code.** The AI's default instinct, fix bugs at the source, is right for code and wrong for applied migrations. Naming the category error directly removes the instinct's grip.

2. **It defines "applied" pessimistically.** The loophole is always "this one probably hasn't run yet." Making committed-or-pushed the threshold replaces guesswork with a checkable fact.

3. **It closes the "harmless edit" gap.** Typo fixes and reformatting feel exempt; explicitly including them prevents the rule from eroding one small edit at a time.

4. **It scripts the pushback.** When a user literally asks to "fix the migration," the AI needs words for the alternative, or it will comply.

## Origin

A developer asked their assistant to widen a too-small column. The AI edited the three-month-old migration that created it, tests passed against a freshly built schema, and the PR merged. Prod kept the narrow column and started truncating data two weeks later when a partner integration sent longer values. The eventual diagnosis took most of a day, because every migration file said the column was already wide enough.
