---
title: Create Indexes Concurrently on Live Tables
slug: create-indexes-concurrently
category: databases
tags: [universal, databases, indexes]
works_with: all
severity: high
one_liner: "Building an index with a write lock on a table production is using"
---

# Create Indexes Concurrently on Live Tables

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents plain CREATE INDEX migrations that block all writes to a busy table for the duration of the build.

**[Copy-paste ready version](../../install/create-indexes-concurrently.md)** — just the instruction block, no explanation.

## The Problem

A slow query needs an index, so the AI writes the textbook fix: `CREATE INDEX idx_orders_user_id ON orders (user_id);`. In Postgres, that statement takes a lock that blocks every INSERT, UPDATE, and DELETE on `orders` until the index finishes building. On a small table that's milliseconds and nobody notices. On a 100-million-row table it's twenty minutes during which checkout cannot write an order. The migration "succeeds"; the business stops anyway.

The reason the AI defaults to the locking form is simple: it's the form in every tutorial, every ORM helper generates it by default, and the concurrent variant comes with annoying caveats that make it look like the advanced option rather than the safe one. `CREATE INDEX CONCURRENTLY` can't run inside a transaction, which means the migration framework needs to be told to disable its transaction wrapper (`disable_ddl_transaction!` in Rails, `atomic = False` in Django), and a failed concurrent build leaves an INVALID index that must be dropped and retried. The AI avoids the caveats by avoiding the safety.

The footgun has engine-specific shapes: Postgres needs `CONCURRENTLY`; MySQL/InnoDB does most index builds online but degrades to locking in specific cases; either way, the question "will this block writes, and for how long?" needs an answer before the migration ships.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Create Indexes Concurrently on Live Tables

NEVER add or drop an index on a production-sized table with the default locking form. Plain `CREATE INDEX` blocks all writes to the table for the entire build, which on large tables means minutes of write outage.

- Postgres: use `CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);` and `DROP INDEX CONCURRENTLY` for removals.
- `CONCURRENTLY` cannot run inside a transaction. Configure the migration accordingly: `disable_ddl_transaction!` (Rails), `atomic = False` (Django), `transaction: false` in the migration tool's terms. A concurrent index migration without this setting will simply fail.
- Handle the failure mode: if a concurrent build dies, it leaves an INVALID index. Make the migration idempotent: drop the invalid index if present, then create.
- MySQL/InnoDB: most secondary index adds are online by default (`ALGORITHM=INPLACE, LOCK=NONE`); state the algorithm explicitly so a silent fallback to a locking rebuild fails loudly instead.
- Before writing the migration, ask or check how big the table is. On genuinely small tables (thousands of rows) the plain form is fine; say that you checked.
- This is about live tables. Brand-new tables created in the same migration can take plain indexes freely.

**Red flags that you're about to violate this:**

- "CREATE INDEX is a standard, safe operation..."
- "The ORM helper generated it this way..."
- "CONCURRENTLY has weird transaction issues, simpler to skip it..."
- "Index creation is fast, the lock won't matter..."
- "I'll use the same pattern as the existing old migrations..."

---

## Why It Works

1. **It reframes which form is "advanced."** The AI treats CONCURRENTLY as the exotic option; stating that the plain form is a write outage on big tables flips the default.

2. **It bundles the caveats instead of letting them deter.** The transaction-wrapper and INVALID-index gotchas are exactly why AIs avoid the safe form; handing over the recipe removes the friction that drove the bad choice.

3. **It forces the size question.** Lock pain scales with table size, which the AI never checks unprompted. Making "how big is this table" a prerequisite turns the silent variable into an explicit one.

## Origin

A team merged an AI-written migration adding a composite index to their largest table during the Tuesday deploy. The build took fourteen minutes; every write to the table queued behind it, the queue exhausted the connection pool, and the app served errors well beyond that one table's traffic. The fix that shipped the next day was the identical index with one extra keyword and one framework flag.
