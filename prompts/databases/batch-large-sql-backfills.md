---
title: Batch Large SQL Backfills
slug: batch-large-sql-backfills
category: databases
tags: [universal, databases, sql]
works_with: all
severity: critical
one_liner: "Backfilling millions of rows in one UPDATE inside one transaction"
---

# Batch Large SQL Backfills

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a single-statement, single-transaction backfill from locking a large table and taking production down with it.

**[Copy-paste ready version](../../install/batch-large-sql-backfills.md)** — just the instruction block, no explanation.

## The Problem

Asked to populate a new `status` column, the AI writes the obvious thing: `UPDATE orders SET status = 'complete' WHERE shipped_at IS NOT NULL;`. One statement, correct logic, looks great in review. On a 50-million-row table, that statement runs for forty minutes inside one giant transaction. It holds row locks the whole time, blocks every write that touches those rows, bloats the WAL, stalls replication, and if anything kills it at minute 39, the entire thing rolls back and you've gained nothing but an outage.

The AI defaults to this because correctness and scale are different questions, and it only checked the first one. The single UPDATE is logically perfect. Nothing in the SQL itself reveals that the table has 50 million rows; the AI has to go ask, and by default it doesn't. The same statement that's fine on a 10,000-row table is an incident on a large one.

Backfills, bulk deletes, and mass data corrections all share the fix: do the work in bounded batches, commit each batch, sleep between them, and make the loop resumable so a crash at 80% doesn't restart at zero.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Batch Large SQL Backfills

NEVER run a backfill, bulk UPDATE, or bulk DELETE as a single statement in a single transaction without first knowing the row count. Above roughly 10,000 affected rows, batch it.

One giant data-change transaction holds locks for its entire runtime, blocks concurrent writes, bloats the WAL/undo log, lags replicas, and loses all progress if interrupted.

- Before writing the statement, check scale: `SELECT count(*) FROM orders WHERE shipped_at IS NOT NULL AND status IS NULL;` State the number out loud in your response.
- Batch by primary key range or with a LIMIT loop, committing each batch:
  `UPDATE orders SET status = 'complete' WHERE id IN (SELECT id FROM orders WHERE shipped_at IS NOT NULL AND status IS NULL LIMIT 5000);`
  Repeat until 0 rows affected.
- Make the loop resumable: the WHERE clause must exclude already-processed rows (`status IS NULL` above), so a crash mid-run resumes instead of restarting.
- Sleep briefly between batches (100-500ms) to let replication catch up and other transactions breathe.
- Bulk DELETEs follow the same rule. For deleting most of a table, prefer copying survivors to a new table or dropping a partition over a giant DELETE.
- Never wrap the whole batched loop in one outer transaction; that defeats the entire point.

**Red flags that you're about to violate this:**

- "One UPDATE statement is the cleanest way to do this..."
- "I don't know how big the table is, but the query is correct..."
- "A single transaction is safer because it's atomic..."
- "Batching adds complexity the user didn't ask for..."
- "It worked instantly on my test data..."

---

## Why It Works

1. **It forces the row count into the open.** The failure lives entirely in unexamined scale. Requiring the AI to run a count and state the number converts an invisible assumption into a visible fact.

2. **It pre-empts the atomicity rationalization.** "One transaction is safer" sounds like wisdom; for bulk data changes it's the exact mechanism of the outage. Naming it flips the instinct.

3. **It demands resumability, not just batching.** A batched loop that restarts from zero after a crash is half a fix. The "exclude processed rows" requirement makes the loop idempotent by construction.

## Origin

A team asked their assistant to backfill a denormalized counter across their events table. The generated migration ran one UPDATE over roughly 80 million rows; it held locks long enough that the web tier exhausted its connection pool waiting, and the deploy was declared failed and rolled back at the 30-minute mark, undoing all of it. The batched version they wrote afterward completed in the background over two hours with zero user impact.
