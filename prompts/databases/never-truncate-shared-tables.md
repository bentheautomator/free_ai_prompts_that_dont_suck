---
title: Never Truncate Tables Other Systems Read
slug: never-truncate-shared-tables
category: databases
tags: [universal, databases, sql]
works_with: all
severity: critical
one_liner: "Truncating a table as cleanup while other services still depend on it"
---

# Never Truncate Tables Other Systems Read

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents "cleanup" truncations of tables that other services, jobs, or reports quietly depend on.

**[Copy-paste ready version](../../install/never-truncate-shared-tables.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in the task, the AI decides a table is cruft. Maybe it's resetting state for a re-import, maybe the table looks like a log nobody reads, maybe the user said "clean up the old events." Out comes `TRUNCATE events;`, instant, satisfying, and unlogged in the row-level sense, meaning there is no per-row undo. Then the analytics pipeline that reads `events` every night produces an empty report, the billing job that aggregates it under-charges every customer, and the data team discovers the table is empty days later, past the point where anyone connects it to "that cleanup PR."

The AI reaches for TRUNCATE because it judges a table's importance by what it can see: the code in this repo. A table that this codebase only writes looks like a write-only log, safely deletable. But databases are integration points. Readers live in other repos, in scheduled jobs, in BI tools, in a Kafka connector, in a CSV export someone in finance runs monthly. None of that is visible from the working directory, so the AI's "nothing uses this" conclusion is structurally unreliable.

TRUNCATE is also worse than DELETE in specific ways the AI rarely mentions: it can't be scoped, it resets sequences, it fires no row triggers, and on most setups it isn't recoverable except from backup.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Truncate Tables Other Systems Read

NEVER truncate or empty a table based on what you can see in the current codebase. "No references in this repo" does not mean "no readers." Databases are integration points; consumers live in other repos, cron jobs, BI dashboards, and pipelines you cannot see.

- Treat TRUNCATE on any non-local database as requiring explicit human confirmation, every time, with the table name and environment stated: "About to TRUNCATE `events` on staging, which removes all 2.1M rows irrecoverably. Confirm?"
- Before proposing it, articulate who might read the table: replication consumers, ETL/analytics jobs, downstream services, reports. If you can't enumerate the readers, you don't know the blast radius.
- Prefer scoped DELETE with a WHERE clause over TRUNCATE; "clean up old events" means `DELETE FROM events WHERE created_at < now() - interval '90 days'` (batched if large), not emptying the table.
- If a full reset is genuinely intended, prefer renaming the table aside (`ALTER TABLE events RENAME TO events_old_20260610`) and creating a fresh one; the data survives until someone confirms nothing broke.
- Remember what TRUNCATE actually does: no row triggers fire, sequences may reset, and there is no row-level undo. Say this when proposing it.
- On local/test databases owned solely by this project, truncate freely.

**Red flags that you're about to violate this:**

- "Nothing in the codebase reads this table..."
- "It's just log data, nobody will miss it..."
- "TRUNCATE is faster and cleaner than DELETE here..."
- "The user said clean up, and this is the cleanest..."
- "We can always regenerate this data later..."

---

## Why It Works

1. **It attacks the visibility fallacy directly.** "No references in this repo" is the load-bearing false premise. Stating that databases have invisible consumers makes the AI's evidence insufficient by definition, not by judgment call.

2. **It demands an enumeration of readers.** Being unable to list consumers becomes the stop signal itself, rather than a gap quietly filled with optimism.

3. **It offers a reversible substitute.** Rename-aside gives the AI a way to fully satisfy "reset this table" while keeping an undo path, so the rule doesn't fight the task.

## Origin

Asked to "reset the import state so we can re-run it," an assistant truncated the staging table the import wrote to. That table was also the source for a nightly revenue rollup consumed by finance. The truncation happened on a Friday; the empty rollups ran twice over the weekend and were emailed to leadership before anyone noticed. Rebuilding the table from upstream sources took three days; the trust in the dashboard took longer.
