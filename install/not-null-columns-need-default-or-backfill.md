### NOT NULL Columns Need a Default or a Backfill

NEVER add a NOT NULL column without a DEFAULT to a table that contains rows. The migration will fail on existing data, or you'll be tempted into an unbatched backfill inside the deploy to make it pass.

"This field is required" describes new records; the constraint applies to all records ever inserted. Bridge the gap explicitly.

- First, check whether the table has rows. On an empty or brand-new table, plain `NOT NULL` is fine; say that you checked.
- If a sensible default exists, use it: `ALTER TABLE users ADD COLUMN locale varchar NOT NULL DEFAULT 'en';` (Postgres 11+ and modern MySQL handle this without rewriting the table; confirm for the engine and version in use.)
- If no constant default makes sense, split the work:
  1. Migration: add the column nullable.
  2. Backfill existing rows in batches, outside the deploy path.
  3. Later migration: `SET NOT NULL` once a check confirms zero NULLs remain. In Postgres, prefer adding a `CHECK (col IS NOT NULL) NOT VALID` then `VALIDATE CONSTRAINT` to avoid a long lock.
- Do not put the backfill UPDATE inside the same migration as the DDL on a large table.
- Application code must start writing the column at step 1, or step 3 never becomes possible.

**Red flags that you're about to violate this:**

- "The field is required, so the column should be NOT NULL..."
- "It worked fine on my local database..."
- "I'll just add a quick UPDATE in the migration to fill old rows..."
- "The table probably doesn't have that many rows..."
- "The ORM generated this migration, so it must be safe..."
