---
title: Drop Columns Only After All Readers Are Gone
slug: drop-columns-only-after-readers-gone
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: critical
one_liner: "Dropping a column in the same deploy that stops reading it"
---

# Drop Columns Only After All Readers Are Gone

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents dropping a database column in the same deploy as the code change that stops using it.

**[Copy-paste ready version](../../install/drop-columns-only-after-readers-gone.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to remove a feature, and it does a satisfyingly complete job: deletes the model field, deletes the references, and writes a migration with `ALTER TABLE users DROP COLUMN legacy_score`. One PR, one deploy, very tidy. Then the deploy rolls out, and for the thirty seconds (or thirty minutes) where old application code is still running against the new schema, every `SELECT * FROM users` from the old code throws `column "legacy_score" does not exist`. Rolling deploys, blue-green, even a single server restarting mid-deploy: there is always a window where old code talks to the new schema.

AI assistants do this because they treat code and schema as one atomic unit. In their mental model, the migration and the code change happen at the same instant. In production they never do. The migration runs first (or last), and the other side of the deploy is live the whole time.

The fix is boring and well-known: removal takes two deploys. Deploy 1 stops all reads and writes of the column. Deploy 2, after deploy 1 is fully rolled out and verified, drops the column. AI assistants will skip this unless told, because the one-deploy version looks cleaner in the diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Drop Columns Only After All Readers Are Gone

NEVER drop a column (or table) in the same deploy as the code change that stops using it. Removal is always at least two deploys.

The core problem: migrations and code do not deploy atomically. During any rollout there is a window where old code runs against the new schema, and old code that still selects the dropped column will crash.

- Deploy 1: remove every read and write of the column from application code. Mark the column ignored in the ORM if it supports it (`ignored_columns` in Rails, `deferred`/removed from the model in others) so `SELECT *` style queries stop referencing it.
- Deploy 2 (a later, separate change, after deploy 1 is fully live): the migration with `DROP COLUMN`.
- The same applies to dropping tables, dropping indexes that queries hint at, and removing enum values.
- If asked to "remove feature X" in one PR, split the work and say so explicitly: "code removal now, column drop in a follow-up after this deploys."
- Rollback check: if deploy 2 is reverted, the app must still work. A dropped column makes the *previous* app version unrunnable, which breaks rollback too.

**Red flags that you're about to violate this:**

- "I'll clean up the schema while I'm at it..."
- "The migration and code change belong in the same PR for atomicity..."
- "Nothing references this column anymore after my change..."
- "It deploys together, so there's no window..."
- "Leaving the column would be dead schema, better to drop it now..."

---

## Why It Works

1. **It reframes deploys as non-atomic.** The AI's default model is "the PR is one unit." Stating plainly that old code always overlaps new schema removes the assumption the failure hides behind.

2. **It names the rollback trap.** Even careful AIs forget that dropping a column doesn't just break the rollout window, it breaks the ability to roll back at all. Forcing that check catches drops that survive the first objection.

3. **It gives the AI a script for pushing back.** "Split into two deploys and say so" turns the rule into an action the AI can take inside a single PR request, instead of silently complying with an unsafe ask.

## Origin

A team asked their assistant to remove a deprecated `plan_tier` field. It produced one beautiful PR: model change, dead code removal, and the `DROP COLUMN` migration. The migration ran at the start of a 20-minute rolling deploy; every not-yet-updated pod threw on `SELECT *` queries for the duration, taking checkout down with it. The column had been unused for a year. The two-deploy version would have cost one extra PR.
