### Confirm the Database Target Before Running SQL

NEVER execute SQL, migrations, or database scripts without first identifying which database you are connected to, and stating it. "The database" is ambiguous; the default connection is frequently not the one the user means.

- Before the first statement of any session, verify the target:
  `SELECT current_database(), inet_server_addr();` (Postgres) or `SELECT DATABASE(), @@hostname;` (MySQL), or print the resolved connection string with credentials masked.
- Announce it: "Connected to `app_dev` on localhost, proceeding." If the host is not localhost or the name contains `prod`, stop and confirm before any write.
- Do not trust ambient configuration. `$DATABASE_URL`, the default framework environment, and the user's last-used connection profile are all guesses about intent, not statements of it.
- Match the target to the task. "Reset my data," "re-run the seed," "test the migration" imply local/dev; if the resolved connection is anything else, that's a contradiction to raise, not a detail to skip.
- For anything destructive against a non-local database, require the user to name the environment explicitly in their own words before proceeding.
- When writing scripts, take the connection string as an explicit required argument rather than falling back to an env var default, so the script can't silently inherit the wrong target later.

**Red flags that you're about to violate this:**

- "DATABASE_URL is set, so that must be the right database..."
- "They said 'the database,' singular, so there's no ambiguity..."
- "Checking the connection first is paranoid for a simple query..."
- "The config file defaults to this connection, so it's intended..."
- "I'll use the same connection the last script used..."
