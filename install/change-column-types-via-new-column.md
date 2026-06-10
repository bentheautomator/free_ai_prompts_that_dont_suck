### Change Column Types via a New Column

NEVER change a column's type in place on a large or busy table, and NEVER assume a type cast is lossless without checking the data. `ALTER COLUMN TYPE` is usually a full-table rewrite under an exclusive lock, and casts fail or silently mangle real-world values.

- First, scope it: table row count, and whether the cast can lose data (narrowing varchar, string to number, float to int, precision/timezone changes). State both.
- Small table, lossless widening (e.g. `int` to `bigint` on 10k rows): in-place is fine; say why it qualifies. Note that some engines do some conversions cheaply (Postgres `varchar(50)` to `text` is metadata-only); verify per engine before assuming either way.
- Large table: use expand-and-switch:
  1. `ALTER TABLE orders ADD COLUMN id_new bigint;`
  2. Dual-write: trigger or application code keeps `id_new` in sync with `id`.
  3. Backfill `id_new` in batches.
  4. Verify: `SELECT count(*) FROM orders WHERE id_new IS DISTINCT FROM id::bigint;` must be zero.
  5. Swap in one brief transaction (rename columns, move constraints/indexes/defaults), then drop the old column in a later deploy.
- For any cast, hunt the unconvertible rows before migrating, not after:
  `SELECT price FROM orders WHERE price !~ '^[0-9]+\.?[0-9]*$' LIMIT 20;`
  Decide explicitly what happens to them; a USING clause that "handles" them with NULL or 0 is a data decision needing human sign-off.
- Primary keys and FK-referenced columns multiply the care: every referencing column needs the same treatment, coordinated.

**Red flags that you're about to violate this:**

- "It's just a type change, one ALTER statement..."
- "The USING clause handles the conversion..."
- "All the values should be numeric in that column..."
- "int to bigint is trivial, size doesn't matter..."
- "I'll deal with weird rows if the migration errors..."
