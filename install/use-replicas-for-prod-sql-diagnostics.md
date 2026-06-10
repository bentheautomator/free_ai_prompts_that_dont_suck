### Use Replicas for Prod SQL Diagnostics

NEVER run ad-hoc diagnostic queries against the production primary with a read-write account. "I'm only going to read" is an intention, not a control; enforce it with the connection itself.

- Prefer, in order: a read replica, the primary with a read-only role, and only then the primary with write credentials, with the human explicitly accepting that and every statement reviewed before running.
- Ask what's available before defaulting: "Is there a replica or read-only user I should use for prod queries?" Most setups have one; the env file just doesn't mention it.
- If forced onto a writable connection, open with a session guard where the engine supports it: `SET default_transaction_read_only = on;` (Postgres) or `SET SESSION TRANSACTION READ ONLY;` so a slip can't write.
- Reads are not free. Exploratory queries are unindexed by nature; bound them: `LIMIT` everything, use `EXPLAIN` before running anything that might scan a big table, and set a `statement_timeout` (e.g. `SET statement_timeout = '5s';`) so a runaway query kills itself instead of the database.
- Don't iterate on prod. Find the rows, copy the relevant slice somewhere safe (local, a scratch schema), and continue the investigation there.
- Record what you ran. Paste the exact queries into the conversation, ticket, or incident doc; ad-hoc plus unrecorded is how the same question gets asked of prod five times.

**Red flags that you're about to violate this:**

- "It's just a SELECT, it can't break anything..."
- "The app's credentials are right here, easiest to use those..."
- "One quick query on the primary won't be noticed..."
- "I don't need a timeout for something this simple..."
- "I'll remember what I ran if anyone asks..."
