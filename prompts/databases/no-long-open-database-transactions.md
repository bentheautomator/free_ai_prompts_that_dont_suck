---
title: No Long-Open Database Transactions
slug: no-long-open-database-transactions
category: databases
tags: [universal, databases, transactions]
works_with: all
severity: high
one_liner: "Holding a transaction open across slow work, blocking everyone else"
---

# No Long-Open Database Transactions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents transactions that stay open across API calls, sleeps, and user prompts, holding locks and stalling the whole database.

**[Copy-paste ready version](../../install/no-long-open-database-transactions.md)** — just the instruction block, no explanation.

## The Problem

The AI learns "wrap it in a transaction for safety" and then applies it to a function that updates a row, calls a payment API with a 30-second timeout, sends an email, and updates the row again. The transaction now spans all of it. Every lock taken by the first update is held while a third-party HTTP call decides whether to respond. Other requests pile up behind those locks; on Postgres, vacuum can't clean up anything the open transaction might still see, so bloat accumulates; and a connection sits in `idle in transaction`, the database status that should be read as a small fire.

The interactive version is worse. The AI opens `BEGIN`, runs a statement, and then pauses to ask the user "does this look right?", leaving the transaction open across human reaction time, lunch, or the rest of the afternoon. The intention is careful; the effect is a lock held for hours.

Transactions are not a safety blanket; they're a lock-holding mechanism with a safety feature attached. The duration of the transaction is the duration of the blocking, so the design goal is short, not wrapped.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Long-Open Database Transactions

NEVER hold a database transaction open across slow or unbounded operations: network calls, file I/O, sleeps, queue publishes, or waiting for human input. A transaction holds locks and pins resources for its entire lifetime; its duration is the duration of the damage.

- Structure code as: gather everything needed (including all external calls) first, then open the transaction, do only database statements, commit. Seconds, not minutes.
- Concretely banned inside a transaction: HTTP/API calls, `sleep()`, sending email, reading user input, large in-memory processing of fetched rows, iterating a slow generator.
- In interactive sessions: do not `BEGIN`, run a statement, and then stop to ask the user a question. If verification needs human eyes, either present the plan before opening the transaction, or use a fast scripted check (row count comparison) inside it.
- If business logic seems to need external calls "inside" the transaction, restructure: write an intent row, commit, perform the call, then record the result in a second short transaction (the outbox pattern). Two short transactions beat one long one.
- Watch for framework-created long transactions: a request-scoped session that stays open while the handler calls three services has this bug without any visible BEGIN.
- Treat `idle in transaction` connections as defects. If your script can be interrupted between BEGIN and COMMIT (debugger, prompt, retry loop), it can strand one.

**Red flags that you're about to violate this:**

- "I'll wrap the whole function in a transaction to be safe..."
- "The API call usually responds quickly..."
- "I'll leave the transaction open so the user can inspect before commit..."
- "Holding locks a bit longer is the price of correctness..."
- "The session manages transactions, I don't need to think about it..."

---

## Why It Works

1. **It corrects the "transaction = safety" frame.** The AI over-applies transactions because it models them as pure protection. Restating them as lock-holding with a cost per second makes "wrap everything" read as expensive instead of careful.

2. **It bans by category, not vibe.** "Slow operations" is judgment; "HTTP calls, sleeps, user input" is a checklist the AI can match against the function body mechanically.

3. **It addresses the interactive trap separately.** Pausing mid-transaction for human review feels like extra safety, which is why it needs its own explicit prohibition with an alternative that preserves the review.

4. **It names the observable symptom.** `idle in transaction` gives the AI (and the human) a concrete thing to look for after the fact, closing the loop between rule and reality.

## Origin

A data-repair script opened a transaction, updated a batch of rows, and then called an external enrichment API per row before committing. The API rate-limited; one batch's transaction stayed open for 40 minutes holding locks on rows the checkout flow also touched. The on-call traced cascading timeouts back to a single connection sitting `idle in transaction` and killed it, rolling back the batch. The rewritten script fetched all enrichment data first, then committed each batch in under a second.
