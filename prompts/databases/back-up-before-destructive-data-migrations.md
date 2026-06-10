---
title: Back Up Before Destructive Data Migrations
slug: back-up-before-destructive-data-migrations
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: critical
one_liner: "Migrations that overwrite or delete data with no copy of the originals"
---

# Back Up Before Destructive Data Migrations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents data-rewriting migrations from destroying the only copy of the values they transform.

**[Copy-paste ready version](../../install/back-up-before-destructive-data-migrations.md)** — just the instruction block, no explanation.

## The Problem

A data migration that transforms values in place is a one-way door, and AI assistants walk through it without checking for a handle on the other side. "Normalize all phone numbers to E.164" becomes `UPDATE users SET phone = normalize(phone);` and the original strings are gone the moment it commits. When the normalize function turns out to mangle extensions, or strips a leading zero that mattered for one country, there is nothing to re-run against. The bug is fixable; the inputs it needs no longer exist.

The AI treats data migrations like pure functions: input, transform, output, done. What's missing from that mental model is that the input is destroyed by the act of writing the output. Code transformations get this for free, the original is in git. Data transformations have no git. Unless the migration itself preserves the originals, the before-state exists only in backups, which are hours old, painful to restore, and missing everything written since.

The insurance is almost embarrassingly cheap: copy the affected values aside first. One `CREATE TABLE ... AS SELECT` before the UPDATE turns "irreversible mistake" into "ten-minute fix."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Back Up Before Destructive Data Migrations

NEVER run a migration or script that overwrites, transforms, or deletes existing data without first preserving the original values. The input to your transformation is destroyed by the transformation; if the logic has a bug, you cannot re-run it.

- Before any in-place transform, snapshot the affected data:
  `CREATE TABLE users_phone_backup_20260610 AS SELECT id, phone FROM users WHERE phone IS NOT NULL;`
  Verify the backup row count matches, then transform.
- Cheaper alternative when the schema allows it: write transformed values into a new column, verify, then swap which column the app reads. The originals stay where they were.
- "There's a nightly backup" is not a plan. It's hours stale, restoring it is a project, and it loses everything written since. A targeted copy of exactly the affected columns costs one statement.
- Scope the backup to what's at risk: `id` plus the columns being changed. You're insuring a transform, not archiving the table.
- State the cleanup plan: backup tables get dropped after a defined verification period (e.g., one week post-deploy), not immediately and not never.
- Deletion counts as transformation. Before a bulk DELETE of rows that took effort to create, the same snapshot rule applies.
- If the user explicitly declines the backup, proceed, but make the trade-off concrete first: "if `normalize()` has a bug, the original phone strings are unrecoverable."

**Red flags that you're about to violate this:**

- "The transformation logic is straightforward, nothing will go wrong..."
- "There are backups if we really need them..."
- "A backup table is clutter we'd have to clean up..."
- "I tested the function on sample values..."
- "It's a normalization, the data isn't really changing..."

---

## Why It Works

1. **It names the destroyed-input problem.** The AI's pure-function mental model hides that writing the output deletes the input. Once stated, "what if I need to re-run this?" has an obvious answer: you can't, unless you saved the originals.

2. **It demotes nightly backups explicitly.** "Backups exist" is the rationalization that defeats this rule most often; spelling out staleness and restore cost stops it from standing in for a one-statement snapshot.

3. **It includes the cleanup contract.** Backup tables that linger forever train teams to stop making them. A defined expiry keeps the practice sustainable, which keeps it happening.

## Origin

A migration normalized mailing addresses through a geocoding cleanup function. The function silently nulled any address it couldn't parse, which turned out to include most addresses with apartment numbers formatted a certain way, roughly 40,000 rows. With no pre-transform copy, recovery meant a point-in-time restore to a side instance and a row-by-row splice, two days of careful work to undo a migration that ran in ninety seconds. A backup table would have made it one UPDATE.
