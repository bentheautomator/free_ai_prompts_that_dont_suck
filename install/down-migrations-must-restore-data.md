### Down-Migrations Must Actually Restore Data

NEVER write a down-migration that restores the schema but not the data, while presenting it as reversible. A down that recreates an empty column after the up dropped a full one is a trap, not a rollback.

Schema symmetry is not reversibility. The question is: if up runs on real data and then down runs, is the database back to where it started?

- For each down you write, classify it honestly:
  - Truly reversible (added a table/column with no data yet; created an index): write the normal down.
  - Lossy: the up destroyed information (DROP COLUMN with data, destructive UPDATE, merging values). Do not fake it.
- For lossy migrations, prefer making the down refuse loudly: raise `IrreversibleMigration` (Rails), `RuntimeError('cannot restore dropped data')`, or the framework equivalent, with a comment explaining what would be needed to actually restore.
- Better: make the up non-lossy so a real down exists. Copy data aside before destroying it:
  `CREATE TABLE users_middle_name_backup AS SELECT id, middle_name FROM users;` then drop; the down restores from the backup table.
- Data-transforming ups (normalizing, reformatting) need the old values preserved somewhere, or an honest irreversible down. A down that "reverses" a lowercase by doing nothing is a no-op wearing a costume.
- When you write an irreversible down, say so in your summary: "this migration cannot be rolled back; here's why."

**Red flags that you're about to violate this:**

- "The down just mirrors the up, easy..."
- "Re-adding the column reverses dropping it..."
- "Nobody actually runs down-migrations anyway..."
- "The framework requires a down, so I'll write something plausible..."
- "The transform is close enough to reversible..."
