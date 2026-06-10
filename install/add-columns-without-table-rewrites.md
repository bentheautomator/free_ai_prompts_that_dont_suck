### Add Columns Without Table Rewrites

NEVER assume an ADD COLUMN is cheap. Whether an ALTER TABLE is a metadata-only change or a full-table rewrite under an exclusive lock depends on the default's volatility, the engine, and the version, and the slow version looks identical in the diff.

- Constant defaults are generally safe on modern engines: `ADD COLUMN flags integer DEFAULT 0` is metadata-only on Postgres 11+ and recent MySQL.
- Volatile defaults rewrite the table: `DEFAULT gen_random_uuid()`, `DEFAULT now()` in some contexts, any function evaluated per row. On a large table this is minutes-to-hours under an exclusive lock.
- For a volatile default on a big table, split it:
  1. `ADD COLUMN token uuid;` (no default, instant)
  2. Backfill in batches outside the deploy.
  3. `ALTER COLUMN token SET DEFAULT gen_random_uuid();` (applies to new rows only, instant)
  4. Add NOT NULL afterward if needed, via validated constraint.
- Before shipping any ALTER on a table that might be large: state the engine and version, state whether this specific operation is metadata-only on it, and state the table's approximate row count. If you can't fill in all three, ask or check; don't ship the guess.
- Dev-database speed is evidence of nothing. Every rewrite is instant on 1,000 rows.
- The same verify-don't-assume applies to other ALTERs: changing types, adding generated columns, and altering NULLability each have their own metadata-vs-rewrite rules per engine.

**Red flags that you're about to violate this:**

- "Adding a column is always fast..."
- "It ran instantly on my local database..."
- "The default makes the migration self-contained, no backfill needed..."
- "Postgres handles defaults efficiently now..."
- "I'll worry about table size if it becomes a problem..."
