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
