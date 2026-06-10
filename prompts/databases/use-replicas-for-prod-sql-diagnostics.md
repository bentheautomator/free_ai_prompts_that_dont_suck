---
title: Use Replicas for Prod SQL Diagnostics
slug: use-replicas-for-prod-sql-diagnostics
category: databases
tags: [universal, databases, sql]
works_with: all
severity: high
one_liner: "Running ad-hoc diagnostic queries on the prod primary with a write account"
---

# Use Replicas for Prod SQL Diagnostics

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents "let me just check something" queries from running on the production primary with write privileges.

**[Copy-paste ready version](../../install/use-replicas-for-prod-sql-diagnostics.md)** — just the instruction block, no explanation.

## The Problem

Debugging a prod issue, the AI wants to "check something": is the data actually wrong, how many rows are affected, what does this user's record look like. So it connects with the application's credentials, the only ones in the env file, straight to the primary, and starts exploring. Three problems ride along. The exploration queries are unindexed by nature (that's why they're exploratory) and can table-scan a multi-hundred-gigabyte table, stealing I/O from real traffic. The connection can write, so one mistyped query during "checking" is a prod data change. And ad-hoc means unrecorded: when the queries matter later, nobody knows exactly what was run.

The AI defaults to the primary because it's the path of least resistance: the credentials at hand are the app's read-write ones, and "I'm only reading" feels like its own safety argument. But "only reading" isn't enforced by intent. It's enforced by connecting as a user that *can't* write, to a host that *isn't* serving your customers' writes. Most production setups have both available, a read replica and a read-only role, and the AI will use neither unless told they exist and are mandatory.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Replicas for Prod SQL Diagnostics

NEVER run ad-hoc diagnostic queries against the production primary with a read-write account. "I'm only going to read" is an intention, not a control; enforce it with the connection itself.

- Prefer, in order: a read replica, the primary with a read-only role, and only then the primary with write credentials, with the human explicitly accepting that and every statement reviewed before running.
- Ask what's available before defaulting: "Is there a replica or read-only user I should use for prod queries?" Most setups have one; the env file just doesn't mention it.
- If forced onto a writable connection, open with a session guard where the engine supports it: `SET default_transaction_read_only = on;` (Postgres) or `SET SESSION TRANSACTION READ ONLY;` so a slip can't write.
- Reads are not free. Exploratory queries are unindexed by nature; bound them: `LIMIT` everything, use `EXPLAIN` before running anything that might scan a big table, and set a `statement_timeout` (e.g. `SET statement_timeout = '5s';`) so a runaway query kills itself instead of the database.
- Don't iterate on prod. Find the rows, copy the relevant slice somewhere safe (local, a scratch schema), and continue the investigation there.
- Record what you ran. Paste the exact queries into the conversation, ticket, or incident doc; ad-hoc plus unrecorded is how the same question gets asked of prod five times.

**Red flags that you're about to violate this:**

- "It's just a SELECT, it can't break anything..."
- "The app's credentials are right here, easiest to use those..."
- "One quick query on the primary won't be noticed..."
- "I don't need a timeout for something this simple..."
- "I'll remember what I ran if anyone asks..."

---

## Why It Works

1. **It converts intent into mechanism.** "I'll only read" gets replaced by connections and session flags that make writing impossible, which is the difference between a promise and a control.

2. **It refutes the free-read assumption.** The AI models SELECT as harmless; naming table scans, missing indexes, and statement timeouts makes the performance cost of exploration concrete and boundable.

3. **It prompts for infrastructure the AI can't see.** Replicas and read-only roles rarely appear in the repo's env files, so the AI doesn't know to use them. Requiring the question surfaces options that change the whole risk profile.

## Origin

While investigating a reporting discrepancy, an assistant ran a series of exploratory aggregations directly on the production primary using the app's credentials. One query joined two large tables without a usable index and ran for nine minutes, during which p99 latency tripled and two batch jobs missed their windows. Nothing was written and nothing was lost, which is exactly why the same pattern repeated twice more before the team created a read-only role and an analyst replica, then made using them a standing rule.
