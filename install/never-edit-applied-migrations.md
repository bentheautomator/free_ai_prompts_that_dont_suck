### Never Edit Applied Migrations

NEVER modify a migration file that may have already been applied to any database (prod, staging, CI, or a teammate's machine). Write a new migration instead.

A migration is an append-only log, not editable source code. Databases track migrations as applied by name/version and will never re-run an edited file, so your edit changes nothing except making the file lie about history.

- To fix a mistake in a previous migration, create a new migration that alters the schema to the corrected state (`ALTER TABLE users ALTER COLUMN email TYPE varchar(320)`), even if the original migration is "obviously wrong."
- Treat a migration as applied unless proven otherwise. Committed and pushed means applied. Merged means applied. Only a migration created in the current working session, never run outside this machine, is safely editable.
- This includes "harmless" edits: renaming the file, reformatting, changing a default, fixing a typo in a column name. Any content change to an applied migration is a violation.
- If asked directly to "fix the migration," say that it has already been applied and propose a corrective follow-up migration instead.
- Exception requires explicit human confirmation that the migration has never run anywhere, including CI.

**Red flags that you're about to violate this:**

- "It's cleaner to fix the mistake at its source..."
- "This migration is only a week old, it probably hasn't run anywhere..."
- "I'll just correct the typo in the original file..."
- "Editing it keeps the migration history tidy..."
- "The user said fix the migration, so they must mean this file..."
