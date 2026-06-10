### Set Lock Timeouts for DDL

ALWAYS set a lock timeout before running DDL against a table with live traffic. A waiting ALTER blockades the table: every query issued after it queues behind it, so one long-running query plus your "instant" migration equals an outage that lasts as long as that query.

- Postgres, at the top of any migration touching a busy table:
  `SET lock_timeout = '5s';`
  The ALTER now fails fast if it can't get the lock, instead of freezing the table while it waits. Pair with `SET statement_timeout` for the DDL's own runtime where appropriate.
- Failing fast requires a retry plan: re-run the migration (manually or with backoff). A migration that occasionally needs a second attempt is healthy; one that can blockade prod is not. Many teams wrap this pattern in helpers or use libraries that do timed-retry DDL; use what the project has.
- MySQL: set `lock_wait_timeout` for the session; the same queueing dynamic applies to metadata locks (a forgotten open transaction can hold an MDL that blocks the ALTER, and the ALTER blocks the world).
- Before heavy DDL, check for long-running queries/transactions on the target table (`pg_stat_activity`) and say what you found; deploying DDL into a known 30-minute query is a choice, not luck.
- This complements, not replaces, choosing non-locking forms (`CREATE INDEX CONCURRENTLY`, metadata-only ALTERs). The timeout protects the acquisition; the right DDL form protects the hold.
- Local and CI databases have no contention, so this failure is invisible everywhere except production. Don't conclude safety from quiet environments.

**Red flags that you're about to violate this:**

- "This ALTER is metadata-only, it takes a millisecond..."
- "Lock timeouts are an ops concern, not a migration concern..."
- "If something's holding a lock, the ALTER will just wait politely..."
- "It applied instantly in staging..."
- "Adding retry logic for a one-line migration is over-engineering..."
