### Dedupe Before Adding Unique Constraints

NEVER add a unique constraint or unique index without first checking the column for existing duplicates in the environment that matters. Production data contains exactly the duplicates the constraint is meant to prevent; that's why someone is asking for it.

- Check first, and report the result:
  `SELECT email, count(*) FROM users GROUP BY email HAVING count(*) > 1;`
  Zero duplicates: proceed with the constraint. Nonzero: deduplication is now part of the task, and it comes first.
- Deduplication is a data decision, not a code decision. Do not silently pick "keep lowest id." Present the options: keep newest, keep the one with activity (orders, logins), merge records, or escalate to a human per pair. Show sample duplicate pairs before deleting anything.
- Mind the children: duplicates often have dependent rows. Re-point children to the surviving row before removing the loser, in a transaction.
- Plan for duplicates created *between* dedupe and constraint: run the dedupe, then add the constraint promptly, and make the dedupe re-runnable in case the gap let new ones in.
- On large tables, add the unique index `CONCURRENTLY` (it can fail gracefully on a race; retry after re-deduping).
- Soft-deleted rows are a classic snag: a unique index over all rows fights with "deleted" duplicates. Consider a partial index: `CREATE UNIQUE INDEX ... ON users (email) WHERE deleted_at IS NULL;`
- Never resolve a failed unique migration by just dropping the constraint requirement; the duplicates remain and so does the bug producing them.

**Red flags that you're about to violate this:**

- "The column should already be unique, the constraint just formalizes it..."
- "The migration passed locally and in CI..."
- "If there are duplicates, I'll keep the first row and drop the rest..."
- "Dedupe is simple, group by and delete the extras..."
- "Soft-deleted rows don't count, the index won't mind them..."
