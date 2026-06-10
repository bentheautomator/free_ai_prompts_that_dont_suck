---
title: Wrap Multi-Step Data Fixes in Transactions
slug: wrap-multi-step-data-fixes-in-transactions
category: databases
tags: [universal, databases, transactions]
works_with: all
severity: high
one_liner: "Running related writes as separate statements that can half-apply"
---

# Wrap Multi-Step Data Fixes in Transactions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents multi-statement data changes from failing halfway and leaving the database in a state nobody designed.

**[Copy-paste ready version](../../install/wrap-multi-step-data-fixes-in-transactions.md)** — just the instruction block, no explanation.

## The Problem

Moving rows between tables takes two statements: insert into the destination, delete from the source. The AI writes them as exactly that, two statements, run one after the other with autocommit on. The insert succeeds; the delete fails on a foreign key it didn't anticipate; and now the rows exist in both tables. Or the order is delete-then-insert and they exist in neither. Either way the database is in a state that no version of the application ever expected, and downstream code starts doing strange things with the duplicates or the gap.

This happens because the AI thinks in scripts, not transactions. It writes a sequence of operations the way it writes a sequence of function calls, assuming the happy path connects them. In autocommit mode, every statement is its own permanent commitment, and the failure of statement three doesn't un-happen statements one and two. The classic textbook example exists for a reason: debit one account, get interrupted, never credit the other. AI-generated fix scripts recreate it constantly with inserts, deletes, and updates across related tables.

The fix is the oldest tool in the relational toolbox. Group the statements that must succeed or fail together, and let the database enforce the "together."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Wrap Multi-Step Data Fixes in Transactions

ALWAYS wrap related write statements in a single explicit transaction when they must succeed or fail as a unit. With autocommit on, each statement commits immediately, and a failure midway leaves a half-applied state no code path expects.

- The test: if statement 2 failed, would the database be in an acceptable state with only statement 1 applied? If not, they belong in one transaction:
  `BEGIN; INSERT INTO archived_orders SELECT * FROM orders WHERE ...; DELETE FROM orders WHERE ...; COMMIT;`
- Classic shapes that need this: move rows between tables (insert+delete), renumber or re-parent rows (update+update), replace a dataset (delete+insert), anything touching two tables that reference each other.
- In application scripts, use the explicit transaction API (`conn.transaction()`, `with session.begin():`, `DB.transaction do`), not a comment saying the steps are related.
- Add verification inside the transaction before committing: check affected row counts, and `ROLLBACK` if they're not what was predicted. A transaction you can still abort is the cheapest undo you will ever get.
- Know the boundary of this rule: huge bulk operations should be batched in many small transactions instead (one giant transaction is its own failure mode). The unit of atomicity is the logical fix, not the whole dataset.
- DDL caveat: some engines (MySQL) auto-commit on DDL statements, so mixing DDL into your transactional fix silently breaks atomicity. Keep schema changes and data fixes in separate units.

**Red flags that you're about to violate this:**

- "These statements run right after each other, nothing happens in between..."
- "Each statement is simple, what could fail..."
- "I'll run them one at a time so I can watch each succeed..."
- "Autocommit is the default, so it must be fine..."
- "Transactions are for application code, this is just a script..."

---

## Why It Works

1. **It gives a mechanical grouping test.** "Would state-after-statement-1-only be acceptable?" converts a vague atomicity instinct into a question with a checkable answer for every pair of statements.

2. **It exposes autocommit as a choice, not a neutral default.** The AI treats the default mode as endorsed; pointing out that autocommit means "every statement is forever" reframes the cost of staying in it.

3. **It weaponizes the open transaction for verification.** Checking row counts before COMMIT turns the transaction from an error-handling mechanism into an active safety check, which catches wrong logic as well as failed statements.

4. **It marks both boundaries.** Naming the bulk-batching exception and the DDL-autocommit trap prevents the rule from being applied where it backfires, which is what gets safety rules abandoned.

## Origin

A cleanup script archived completed orders: insert into the archive table, then delete from the live one, as two autocommitted statements in a loop. Midway through, the archive table hit a disk quota and inserts began failing; the loop's error handling skipped ahead, and the deletes kept running. About 12,000 orders were removed from the live table without ever landing in the archive. They were recovered from backup, minus the day's status updates, which support re-entered by hand.
