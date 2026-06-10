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
