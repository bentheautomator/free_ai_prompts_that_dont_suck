---
title: Dedupe Before Adding Unique Constraints
slug: dedupe-before-unique-constraints
category: databases
tags: [universal, databases, migrations]
works_with: all
severity: high
one_liner: "Adding a unique constraint to a column that already contains duplicates"
---

# Dedupe Before Adding Unique Constraints

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents unique-constraint migrations that fail on existing duplicates, or dedupe scripts that delete the wrong copies.

**[Copy-paste ready version](../../install/dedupe-before-unique-constraints.md)** — just the instruction block, no explanation.

## The Problem

"Emails should be unique" is a one-line requirement, and the AI produces a one-line migration: `CREATE UNIQUE INDEX idx_users_email ON users (email);`. On every database where it was tested, that works, because dev and CI data doesn't have duplicates. Production does, because production accumulated three years of the exact bug this constraint is meant to prevent. The migration fails mid-deploy with `could not create unique index: key is duplicated`, and now the release train is stopped on the tracks while someone figures out what to do with 217 pairs of duplicate users at 5 p.m.

The deeper trap is the AI's instinctive recovery: write a quick dedupe that keeps one row per email and deletes the rest. Which one does it keep? `MIN(id)` is the popular guess, the *oldest* row, while the customer has been actively using the *newest* one, the one with their current password and order history. A careless dedupe converts a failed migration into actual data loss, and the deleted duplicates often have child rows (orders, sessions) that either block the delete or get cascaded into oblivion.

Existing duplicates aren't an obstacle to the migration; they're the first half of the task. The constraint is the second half.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Dedupe Before Adding Unique Constraints

NEVER add a unique constraint or unique index without first checking the column for existing duplicates in the environment that matters. Production data contains exactly the duplicates the constraint is meant to prevent; that's why someone is asking for it.

- Check first, and report the result:
  `SELECT email, count(*) FROM users GROUP BY email HAVING count(*) > 1;`
  Zero duplicates: proceed with the constraint. Nonzero: deduplication is now part of the task, and it comes first.
- Deduplication is a data decision, not a code decision. Do not silently pick "keep lowest id." Present the options: keep newest, keep the one with activity (orders, logins), merge records, or escalate to a human per pair. Show sample duplicate pairs before deleting anything.
- Mind the children: duplicates often have dependent rows. Re-point children to the surviving row before removing the loser, in a transaction.
- Plan for duplicates created *between* dedupe and constraint: run the dedupe, then add the constraint promptly, and make the dedupe re-runnable in case the gap let new ones in.
- On large tables, add the unique index `CONCURRENTLY` (it can fail gracefully on a race; retry after re-deduping).
- Soft-deleted rows are a classic snag: a unique index over all rows fights with "deleted" duplicates. Consider a partial index: `CREATE UNIQUE INDEX ... ON users (email) WHERE deleted_at IS NULL;`
- Never resolve a failed unique migration by just dropping the constraint requirement; the duplicates remain and so does the bug producing them.

**Red flags that you're about to violate this:**

- "The column should already be unique, the constraint just formalizes it..."
- "The migration passed locally and in CI..."
- "If there are duplicates, I'll keep the first row and drop the rest..."
- "Dedupe is simple, group by and delete the extras..."
- "Soft-deleted rows don't count, the index won't mind them..."

---

## Why It Works

1. **It reorders the task.** The AI sees "add constraint" as the task and duplicates as a surprise; declaring dedupe the first half of the same task means the GROUP BY check happens before the migration exists, not after it fails.

2. **It blocks the reflexive MIN(id) dedupe.** The worst outcomes come from the recovery, not the failed migration. Forcing the keep-which-row question to a human turns silent data loss into a reviewed decision.

3. **It anticipates the race and the soft-delete snag.** These two are where careful first attempts still fail; naming them upgrades the fix from "works once" to "works in the environment where it runs."

## Origin

A uniqueness migration on a customers table failed in production, and the follow-up dedupe kept the lowest id per email. For 64 customers, that resurrected abandoned accounts from years earlier, customers suddenly saw old addresses and empty order histories, while their active accounts were deleted with their sessions. Support tickets, manual merges from backup, and an apology email followed. The GROUP BY query that would have started the right conversation takes about a second to run.
