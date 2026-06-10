---
title: Down-Migrations Must Actually Restore Data
slug: down-migrations-must-restore-data
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: critical
one_liner: "Writing a down-migration that restores the schema but not the data"
---

# Down-Migrations Must Actually Restore Data

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents down-migrations that look reversible but silently lose data when anyone actually runs them.

**[Copy-paste ready version](../../install/down-migrations-must-restore-data.md)** — just the instruction block, no explanation.

## The Problem

Every migration framework asks for a `down`, and the AI dutifully provides one. Up: `DROP COLUMN middle_name`. Down: `ADD COLUMN middle_name varchar`. Symmetric, passes the linter, looks like a perfect mirror. Except it isn't one: the up threw away every value in that column, and the down recreates an empty husk. The pair round-trips the *schema* and destroys the *data*. The same lie appears in subtler costumes: up lowercases all emails, down is a no-op; up merges two columns into one, down splits by a delimiter that the data never reliably contained.

AI assistants write these because the framework's shape rewards them. The contract appears to be "down reverses up," and at the DDL level it does. The assistant pattern-matches structural symmetry and ships it. Nobody runs the down in testing, so the first execution is during a real rollback, which is to say during an incident, which is to say at the exact moment a silent data loss hurts most.

A down-migration that cannot restore the data is worse than no down-migration, because it converts "we know we can't roll back" into "we think we can, and we'll find out we couldn't after we did."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Down-Migrations Must Actually Restore Data

NEVER write a down-migration that restores the schema but not the data, while presenting it as reversible. A down that recreates an empty column after the up dropped a full one is a trap, not a rollback.

Schema symmetry is not reversibility. The question is: if up runs on real data and then down runs, is the database back to where it started?

- For each down you write, classify it honestly:
  - Truly reversible (added a table/column with no data yet; created an index): write the normal down.
  - Lossy: the up destroyed information (DROP COLUMN with data, destructive UPDATE, merging values). Do not fake it.
- For lossy migrations, prefer making the down refuse loudly: raise `IrreversibleMigration` (Rails), `RuntimeError('cannot restore dropped data')`, or the framework equivalent, with a comment explaining what would be needed to actually restore.
- Better: make the up non-lossy so a real down exists. Copy data aside before destroying it:
  `CREATE TABLE users_middle_name_backup AS SELECT id, middle_name FROM users;` then drop; the down restores from the backup table.
- Data-transforming ups (normalizing, reformatting) need the old values preserved somewhere, or an honest irreversible down. A down that "reverses" a lowercase by doing nothing is a no-op wearing a costume.
- When you write an irreversible down, say so in your summary: "this migration cannot be rolled back; here's why."

**Red flags that you're about to violate this:**

- "The down just mirrors the up, easy..."
- "Re-adding the column reverses dropping it..."
- "Nobody actually runs down-migrations anyway..."
- "The framework requires a down, so I'll write something plausible..."
- "The transform is close enough to reversible..."

---

## Why It Works

1. **It splits schema symmetry from data reversibility.** The AI conflates the two because DDL-level mirroring looks complete. Making the round-trip-on-real-data question explicit breaks the pattern-match.

2. **It legitimizes refusing.** Frameworks pressure the AI into writing *something* for down; blessing `IrreversibleMigration` as the correct answer removes the incentive to fake one.

3. **It upgrades the up instead of just policing the down.** The backup-table pattern means the right answer is often a better up-migration, which is a constructive move the AI can make without pushing back on the task at all.

## Origin

A release went sideways and the on-call ran the standard rollback, which executed the down-migrations for the release. One of them "reversed" a column drop by re-adding the column, empty. The application came back healthy, and for six hours wrote new rows alongside 2 million old ones whose shipping instructions were now NULL. Recovery meant splicing a backup into a live table. The post-incident review's first action item: down-migrations that can't restore data must say so by raising.
