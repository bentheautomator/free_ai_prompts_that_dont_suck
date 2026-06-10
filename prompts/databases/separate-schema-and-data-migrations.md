---
title: Separate Schema and Data Migrations
slug: separate-schema-and-data-migrations
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "Bundling a big data backfill into the same migration as the schema change"
---

# Separate Schema and Data Migrations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents migrations that mix DDL with bulk data changes, blocking deploys and breaking atomicity in both directions.

**[Copy-paste ready version](../../install/separate-schema-and-data-migrations.md)** — just the instruction block, no explanation.

## The Problem

Asked to add a `full_name` column populated from `first_name` and `last_name`, the AI writes one self-contained migration: add the column, `UPDATE users SET full_name = first_name || ' ' || last_name`, maybe set NOT NULL at the end. Self-contained is the problem. Migrations run inside the deploy's critical path, frequently with a timeout, often inside a transaction, and always while the release waits. The schema part takes milliseconds. The data part takes as long as the table is big, on ten million rows, long enough to time out the deploy, hold locks across the whole UPDATE, or both. Now a release is stuck mid-pipeline because of a backfill that had no reason to be there.

The bundling also poisons failure handling. If the migration is transactional and the UPDATE dies at row 9 million, the whole thing rolls back, including the column, and the deploy retries the entire slow path from zero. If it's not transactional, the failure leaves the column added and the data half-filled, a state the migration can't be cleanly re-run against unless someone wrote it idempotently, which the bundled version never is.

Schema changes and data changes have different shapes: DDL is fast, must run in the deploy path, and is all-or-nothing; backfills are slow, should run *outside* the deploy path, and must be batched, resumable, and interruptible. One file can't serve both masters.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Separate Schema and Data Migrations

NEVER bundle a bulk data change into the same migration as a schema change on a table of production size. DDL belongs in the deploy path; backfills don't. They have opposite requirements, and bundling gives you the worst of both.

- Structure the work as three independent steps:
  1. Schema migration: `ALTER TABLE users ADD COLUMN full_name text;` Fast, transactional, deploy-path.
  2. Backfill: a batched, resumable task run *outside* the deploy (background job, rake/management task, ops runbook step), committing per batch. Not blocking the release.
  3. Constraint migration (if needed): a later migration adds NOT NULL/validation once the backfill is verified complete.
- A migration should finish in seconds. If its runtime scales with the table's row count, it's carrying a backfill that wants to be a task.
- Small lookup tables are exempt; updating 50 rows of reference data inline is fine. Say the size when claiming the exemption.
- New code must tolerate the gap between steps 1 and 3: the column exists but is partially NULL. Write the reading code accordingly (coalesce, fallback to the old fields).
- Don't let frameworks blur this: `RunPython`/`execute` blocks inside schema migrations are where bundled backfills hide. The framework allowing it doesn't make the deploy path the right place for it.
- If the team's process genuinely requires data migrations as migration files, keep them in *separate* files from DDL, batched and idempotent, and flag the runtime expectation in the PR.

**Red flags that you're about to violate this:**

- "The migration should fully set up the column, data included..."
- "It's one logical change, so one migration file..."
- "The UPDATE will be quick enough during the deploy..."
- "Splitting it means the column is briefly half-empty..."
- "The framework lets me put Python in the migration, so it belongs there..."

---

## Why It Works

1. **It assigns the two workloads to their right venues.** The AI bundles because "one logical change" feels like one file; contrasting deploy-path DDL with out-of-band backfill gives it a principled split instead of an aesthetic one.

2. **It supplies a mechanical smell test.** "Runtime scales with row count" identifies a smuggled backfill without needing judgment about any particular table's size.

3. **It legitimizes the intermediate state.** Fear of the partially-NULL gap is what drives bundling; explicitly requiring code to tolerate the gap makes the safe sequence feel complete rather than sloppy.

4. **It calls out the framework loophole.** `RunPython` inside a schema migration is exactly where this failure hides from review; naming it makes the hiding place searchable.

## Origin

A release containing "add and populate a normalized phone column" hit the deploy pipeline's 10-minute migration timeout at minute 10 of an estimated 55. The pipeline killed the migration, the transaction rolled back the column, and the deploy marked itself failed, three times, as retries hit the same wall. The release that finally shipped that night contained the ALTER alone; the backfill ran as a background job over the next day, invisible to everyone.
