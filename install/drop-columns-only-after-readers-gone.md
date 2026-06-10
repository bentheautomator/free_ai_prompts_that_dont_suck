### Drop Columns Only After All Readers Are Gone

NEVER drop a column (or table) in the same deploy as the code change that stops using it. Removal is always at least two deploys.

The core problem: migrations and code do not deploy atomically. During any rollout there is a window where old code runs against the new schema, and old code that still selects the dropped column will crash.

- Deploy 1: remove every read and write of the column from application code. Mark the column ignored in the ORM if it supports it (`ignored_columns` in Rails, `deferred`/removed from the model in others) so `SELECT *` style queries stop referencing it.
- Deploy 2 (a later, separate change, after deploy 1 is fully live): the migration with `DROP COLUMN`.
- The same applies to dropping tables, dropping indexes that queries hint at, and removing enum values.
- If asked to "remove feature X" in one PR, split the work and say so explicitly: "code removal now, column drop in a follow-up after this deploys."
- Rollback check: if deploy 2 is reverted, the app must still work. A dropped column makes the *previous* app version unrunnable, which breaks rollback too.

**Red flags that you're about to violate this:**

- "I'll clean up the schema while I'm at it..."
- "The migration and code change belong in the same PR for atomicity..."
- "Nothing references this column anymore after my change..."
- "It deploys together, so there's no window..."
- "Leaving the column would be dead schema, better to drop it now..."
