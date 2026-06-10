---
title: Verify SQL Affected Row Counts
slug: verify-sql-affected-row-counts
category: databases
tags: [universal, databases, sql]
works_with: all
severity: critical
one_liner: "Running DML, ignoring the row count, and moving on past a disaster"
---

# Verify SQL Affected Row Counts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents data changes from succeeding at the wrong scale while the AI reads the row count and learns nothing.

**[Copy-paste ready version](../../install/verify-sql-affected-row-counts.md)** — just the instruction block, no explanation.

## The Problem

Every UPDATE and DELETE comes back with a confession attached: `UPDATE 48213`. The AI was expecting to fix one user's record. It reads the output, reports "the update completed successfully," and moves to the next task. The database told it, in plain numerals, that the predicate matched 48,213 rows instead of one, and the information bounced off, because the AI was checking for *errors*, and there wasn't one. Statements that do catastrophic things at the wrong scale succeed cheerfully; "no error" and "did what was intended" are different claims, and only the first one is visible in the exit code.

The inverse failure is quieter but corrosive: `UPDATE 0`. The fix the AI just "applied" matched nothing, wrong ID, typo in the predicate, row already deleted, and it reports success anyway, because zero rows is also not an error. The user believes their data is fixed. It isn't. Nobody discovers this until the original complaint comes back angrier.

What's missing is a prediction. A row count is only meaningful against an expectation, and the expectation has to exist *before* the statement runs, otherwise whatever number comes back gets rationalized as plausible. Stating "this should affect exactly 3 rows" first is what turns the database's confession into a check that can actually fail.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify SQL Affected Row Counts

ALWAYS state the expected number of affected rows before running an UPDATE, DELETE, or INSERT...SELECT, and ALWAYS compare the actual count against it afterward. "No error" means the syntax was valid; the row count is the only output that says whether the statement did what was intended.

- Before executing, write the expectation: "this should affect exactly 1 row" or "roughly 200, the orders from yesterday's incident window." Exact when possible, bounded when not.
- After executing, compare and report: "expected 1, got 1." On mismatch, stop and investigate before any further statements; do not proceed on top of a wrong-scale change.
- Treat both directions as failures:
  - More than expected: the predicate is broader than intended. If inside an open transaction, ROLLBACK; if not, start incident handling (what changed, can it be restored), not the next task.
  - Zero when expecting nonzero: the fix didn't happen. Find out why (wrong key? already changed? wrong database?) instead of reporting success.
- In scripts, make the check executable: capture `cursor.rowcount` / `result.rowcount` / `ROW_COUNT()` and fail loudly on mismatch:
  `if cur.rowcount != 1: raise RuntimeError(f'expected 1 row, got {cur.rowcount}'); conn.rollback()`
- For risky DML, run inside an explicit transaction so the count arrives while ROLLBACK is still an option, the cheapest undo that exists.
- Batched operations get per-batch expectations (the batch size, until the final partial batch) and a running total compared to the upfront count.

**Red flags that you're about to violate this:**

- "The statement executed without errors, done..."
- "48,000 rows... the table is big, that's probably normal..."
- "Zero rows affected, must have already been fixed..."
- "I don't have a precise expectation, I'll just run it and see..."
- "Checking row counts on every statement is excessive..."

---

## Why It Works

1. **It separates "no error" from "as intended."** The AI's success test is exception-shaped; pointing out that wrong-scale statements succeed silently moves the verification burden to the one output that reflects intent.

2. **It forces the prediction to precede the result.** A count read without a prior expectation gets rationalized ("big table, probably normal"); committing to a number first creates a check that can actually fail.

3. **It scripts both failure directions.** Too-many and zero have opposite responses (rollback/incident vs. investigate-why-nothing), and naming both prevents the zero case from masquerading as success.

4. **It pairs the check with the undo window.** Counting inside an open transaction is the difference between catching a disaster and merely documenting one.

## Origin

A support-driven fix was supposed to reset the onboarding state for one customer org. The script's predicate joined through a table where the org's ID appeared as a default value, and the UPDATE returned a five-digit row count, which was logged, reported as "completed successfully," and noticed eleven hours later when other customers' onboarding flows restarted from step one. The statement had announced the blast radius in its own output; nothing and no one was listening, because nothing had been told what number to expect.
