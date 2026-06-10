### Back Up Before Destructive Data Migrations

NEVER run a migration or script that overwrites, transforms, or deletes existing data without first preserving the original values. The input to your transformation is destroyed by the transformation; if the logic has a bug, you cannot re-run it.

- Before any in-place transform, snapshot the affected data:
  `CREATE TABLE users_phone_backup_20260610 AS SELECT id, phone FROM users WHERE phone IS NOT NULL;`
  Verify the backup row count matches, then transform.
- Cheaper alternative when the schema allows it: write transformed values into a new column, verify, then swap which column the app reads. The originals stay where they were.
- "There's a nightly backup" is not a plan. It's hours stale, restoring it is a project, and it loses everything written since. A targeted copy of exactly the affected columns costs one statement.
- Scope the backup to what's at risk: `id` plus the columns being changed. You're insuring a transform, not archiving the table.
- State the cleanup plan: backup tables get dropped after a defined verification period (e.g., one week post-deploy), not immediately and not never.
- Deletion counts as transformation. Before a bulk DELETE of rows that took effort to create, the same snapshot rule applies.
- If the user explicitly declines the backup, proceed, but make the trade-off concrete first: "if `normalize()` has a bug, the original phone strings are unrecoverable."

**Red flags that you're about to violate this:**

- "The transformation logic is straightforward, nothing will go wrong..."
- "There are backups if we really need them..."
- "A backup table is clutter we'd have to clean up..."
- "I tested the function on sample values..."
- "It's a normalization, the data isn't really changing..."
