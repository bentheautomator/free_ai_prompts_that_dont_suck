---
title: Roll Back Transactions on Error
slug: roll-back-transactions-on-error
category: error-handling
tags: [universal, errors]
works_with: all
severity: critical
one_liner: "AI catching errors mid-transaction and committing the half-finished work"
---

# Roll Back Transactions on Error

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents error handlers from letting half of a multi-step write become permanent.

**[Copy-paste ready version](../../install/roll-back-transactions-on-error.md)** — just the instruction block, no explanation.

## The Problem

A transfer debits one account, credits another, and writes an audit row — three statements that must land together or not at all. Then an AI adds error handling *inside* the sequence: `try: credit(dst) except Exception: logger.error("credit failed")` — and execution continues to `commit()`. The debit is now permanent, the credit never happened, and the database is in a state that no version of the business logic ever intended. The whole point of the transaction was to make this impossible; the catch block politely defused it.

The pattern has several disguises. Catching per-statement inside a transaction and continuing to commit. Calling `commit()` in a `finally` block ("make sure we always commit" — yes, including the broken runs). Opening a transaction and never wiring the error path to `rollback()`, leaving the connection in an aborted state that poisons every later query with `current transaction is aborted` (PostgreSQL) or, with some drivers and pool configs, leaks uncommitted state into the next request that borrows the connection.

Assistants produce these because the try/except is generated at statement granularity while transactional integrity lives at *block* granularity. Each catch looks locally reasonable; the unit-of-work boundary it punctures is invisible at that zoom level.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Roll Back Transactions on Error

Inside a transaction, any error means the whole transaction rolls back. NEVER catch an exception mid-transaction and continue to commit — partial units of work must not become permanent.

- The transaction is the try scope: one try around the whole unit of work, with `except: rollback(); raise` — not per-statement catches that fall through to commit
- Never call `commit()` in a `finally` block or after a swallowed exception; commit belongs only on the path where every statement succeeded
- Prefer the language's transactional scope constructs, which encode commit-on-success/rollback-on-error correctly: `with session.begin():` (SQLAlchemy), `transaction.atomic()` (Django), `BEGIN/COMMIT` wrappers in your DB library, `TransactionScope` in .NET — over hand-wired commit/rollback
- If you catch an error inside a transaction to handle it (e.g. fall back to an alternate write), the handling must stay transaction-aware: either the transaction is still valid in your database (it isn't in PostgreSQL after an error, without savepoints), or you roll back / roll back to a savepoint first
- Always wire the error path: an opened transaction must reach exactly one of commit or rollback on every code path, including early returns — leaked open transactions hold locks and poison pooled connections
- Side effects that can't roll back (HTTP calls, emails, file writes) don't belong inside the transaction; do them after commit, or design compensation for them

**Red flags that you're about to violate this:**
- "I'll catch the error on this statement so the rest of the transaction completes..."
- "Commit in finally guarantees we never lose the work..."
- "Logging the failed update is enough; the other writes are fine..."
- "Rollback throws away the successful statements, which seems wasteful..."
- "I'll handle the constraint violation inline and keep going..."

---

## Why It Works

1. **It re-zooms the error handling to the unit-of-work boundary.** The model generates catches per statement; declaring "the transaction is the try scope" relocates the handler to the only granularity at which atomicity is decidable.

2. **It attacks the 'wasteful rollback' intuition.** Rolling back successful statements feels like losing work; naming partial state as something *no version of the logic intended* reframes that loss as the feature.

3. **It pushes toward constructs that can't be miswired.** Context managers and transactional scopes make commit-on-success/rollback-on-error structural rather than remembered — the class of bug disappears instead of being avoided.

4. **It covers the aborted-connection footgun.** Continuing after an error inside a PostgreSQL transaction fails in a confusing, downstream way; warning about it pre-empts the "handle inline and keep going" variant that looks fine in SQLite-based tests.

## Origin

An inventory system reserved stock and recorded the reservation in one transaction. An assistant, fixing a bug where one insert occasionally hit a constraint violation, wrapped just that insert in try/except-log and let the function proceed to commit. From then on, every constraint hit committed a stock decrement with no reservation record — invisible inventory shrinkage, a few units a day. A quarterly stock audit found the warehouse "missing" thousands of units that had never been sold, and the reconciliation traced back to a four-line catch block that had been carefully logging each occurrence the whole time.
