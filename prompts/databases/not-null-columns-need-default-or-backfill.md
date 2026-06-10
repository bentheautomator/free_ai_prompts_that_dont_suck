---
title: NOT NULL Columns Need a Default or a Backfill
slug: not-null-columns-need-default-or-backfill
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "Adding a NOT NULL column with no default to a table that has rows"
---

# NOT NULL Columns Need a Default or a Backfill

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents migrations that add NOT NULL columns to populated tables and fail, or lock the table trying to succeed.

**[Copy-paste ready version](../../install/not-null-columns-need-default-or-backfill.md)** — just the instruction block, no explanation.

## The Problem

The model says the field is required, so the AI writes the migration that says so: `ALTER TABLE users ADD COLUMN locale varchar NOT NULL;`. On the empty database where it gets tested, this works perfectly. On prod, where `users` has rows, the migration fails instantly: existing rows would violate the constraint, and the database refuses. Best case, the deploy aborts. Worse case, the framework half-applied a multi-statement migration first and you're now stuck between schema versions during a deploy window.

The AI does this because it translates application-level requirements directly into DDL. "This field is required" is true for new records; the migration applies to all records, including the millions that existed before the field did. Those are two different claims, and only the AI's version fails loudly. The schema-only test environment hides the problem completely, which is why this bug ships so often.

The sibling mistake is "fixing" it with a naive three-step in one migration: add nullable, `UPDATE` every row, set NOT NULL. Correct logic, but on a big table that's an unbatched backfill inside a deploy, which trades the instant failure for a long lock.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### NOT NULL Columns Need a Default or a Backfill

NEVER add a NOT NULL column without a DEFAULT to a table that contains rows. The migration will fail on existing data, or you'll be tempted into an unbatched backfill inside the deploy to make it pass.

"This field is required" describes new records; the constraint applies to all records ever inserted. Bridge the gap explicitly.

- First, check whether the table has rows. On an empty or brand-new table, plain `NOT NULL` is fine; say that you checked.
- If a sensible default exists, use it: `ALTER TABLE users ADD COLUMN locale varchar NOT NULL DEFAULT 'en';` (Postgres 11+ and modern MySQL handle this without rewriting the table; confirm for the engine and version in use.)
- If no constant default makes sense, split the work:
  1. Migration: add the column nullable.
  2. Backfill existing rows in batches, outside the deploy path.
  3. Later migration: `SET NOT NULL` once a check confirms zero NULLs remain. In Postgres, prefer adding a `CHECK (col IS NOT NULL) NOT VALID` then `VALIDATE CONSTRAINT` to avoid a long lock.
- Do not put the backfill UPDATE inside the same migration as the DDL on a large table.
- Application code must start writing the column at step 1, or step 3 never becomes possible.

**Red flags that you're about to violate this:**

- "The field is required, so the column should be NOT NULL..."
- "It worked fine on my local database..."
- "I'll just add a quick UPDATE in the migration to fill old rows..."
- "The table probably doesn't have that many rows..."
- "The ORM generated this migration, so it must be safe..."

---

## Why It Works

1. **It names the two-claims confusion.** "Required for new records" versus "true of all existing rows" is the exact conceptual slip; once distinguished, the right migration shape follows naturally.

2. **It pre-positions the empty-table check.** Most of the time the AI doesn't know if the table has data. Forcing the check first routes empty tables to the simple path and populated ones to the safe path, instead of guessing.

3. **It blocks the second-order mistake.** The obvious fix (backfill inline) is its own incident on large tables. Closing that door in the same instruction prevents the rule from creating a worse workaround.

## Origin

A migration adding a required `tenant_id` to a junction table sailed through review and CI, both of which ran against empty schemas. In production the table had four million rows and the migration failed mid-deploy, after a preceding migration in the same release had already applied, leaving the schema in a state neither the old nor new code expected. The rollout was frozen for an hour while someone hand-walked the schema forward.
