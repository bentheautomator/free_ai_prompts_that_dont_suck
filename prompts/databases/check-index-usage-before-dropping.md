---
title: Check Index Usage Before Dropping
slug: check-index-usage-before-dropping
category: databases
tags: [universal, databases, indexes]
works_with: all
severity: high
one_liner: "Dropping an index that looked unused but was holding up production queries"
---

# Check Index Usage Before Dropping

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents dropping indexes based on code reading instead of usage statistics, and the query-plan collapse that follows.

**[Copy-paste ready version](../../install/check-index-usage-before-dropping.md)** — just the instruction block, no explanation.

## The Problem

During a cleanup or a schema review, the AI spots an index it can't connect to any query in the codebase and confidently writes `DROP INDEX idx_orders_customer_created;`. The reasoning is code-shaped: no query in this repo mentions those columns together, therefore unused, therefore cruft. But the planner doesn't read your repo. That index might serve a query in the admin tool, the analytics job, the other service sharing this database, or an ORM-generated query whose SQL never appears as text anywhere. It might be the index that makes the nightly export finish before morning.

The failure mode is asymmetric in a particularly nasty way. Dropping an index is instant and silent, no error, nothing breaks at drop time. The damage arrives later as performance collapse: the hourly job that took 40 seconds now takes 6 hours, the endpoint that did index scans now sequential-scans 80 million rows under load. And rebuilding a large index isn't an instant undo; it's a long, resource-hungry operation you now have to do under pressure (concurrently, if you remembered).

Databases keep actual usage statistics precisely for this question. `pg_stat_user_indexes` will tell you the index was scanned 4 million times this week. The AI just has to ask the database instead of inferring from the code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Index Usage Before Dropping

NEVER drop an index because the codebase doesn't appear to use it. Query planners don't read your repo; the index may serve other services, admin tools, scheduled jobs, or ORM-generated queries that never appear as literal SQL.

- Check actual usage statistics from the database before proposing a drop:
  Postgres: `SELECT idx_scan, last_idx_scan FROM pg_stat_user_indexes WHERE indexrelname = 'idx_orders_customer_created';`
  MySQL: `SELECT * FROM sys.schema_unused_indexes;`
  Report the numbers in your response.
- Zero scans is necessary but not sufficient: stats may have been reset recently, and some workloads are monthly or quarterly. Ask how long the stats window covers and whether periodic jobs exist before trusting a zero.
- Never drop an index that backs a constraint (unique, primary key, FK support); the constraint, not query speed, is its job.
- Prefer a reversible decommission: note the full `CREATE INDEX` statement in the PR so restoration is copy-paste, and on engines that support it, make the index invisible first (`ALTER INDEX ... INVISIBLE` in MySQL) and watch for regressions before the real drop.
- Drop with `DROP INDEX CONCURRENTLY` (Postgres) on live tables, same locking logic as creation.
- Remember the recovery asymmetry and say it when proposing the drop: dropping is instant, rebuilding on a large table takes hours, under incident pressure.

**Red flags that you're about to violate this:**

- "No query in the codebase uses these columns..."
- "This index is redundant, the other one probably covers it..."
- "Unused indexes just slow down writes, dropping is a free win..."
- "If something needs it, we'll just add it back..."
- "It has a weird name, it's clearly leftover from something old..."

---

## Why It Works

1. **It replaces inference with measurement.** "The code doesn't use it" is the false syllogism at the core of this failure; pointing at `pg_stat_user_indexes` gives the AI a strictly better evidence source it didn't know to consult.

2. **It complicates the zero.** Even real statistics mislead when the window is short or the workload is periodic; requiring the window question prevents a freshly-reset counter from green-lighting a drop.

3. **It prices the undo.** "We'll add it back" assumes symmetry; stating that rebuild takes hours under pressure makes the true cost of being wrong part of the proposal.

4. **It provides a staged retreat.** Invisible-first and saved-DDL options let cleanup proceed while keeping a fast path back, which makes the careful route compatible with the cleanup impulse instead of opposed to it.

## Origin

A schema-tidying PR removed five indexes flagged as "not referenced in code." Four were genuinely dead. The fifth served the ORM-generated pagination query of an internal admin tool living in a different repository; its list view went from 200ms to 90 seconds, which surfaced as a support team outage two days later, nowhere near the deploy that caused it. The index took three hours to rebuild concurrently, during which the support queue was worked from spreadsheet exports.
