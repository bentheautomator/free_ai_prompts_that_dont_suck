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
