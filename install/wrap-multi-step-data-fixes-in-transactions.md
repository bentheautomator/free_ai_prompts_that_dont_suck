### Wrap Multi-Step Data Fixes in Transactions

ALWAYS wrap related write statements in a single explicit transaction when they must succeed or fail as a unit. With autocommit on, each statement commits immediately, and a failure midway leaves a half-applied state no code path expects.

- The test: if statement 2 failed, would the database be in an acceptable state with only statement 1 applied? If not, they belong in one transaction:
  `BEGIN; INSERT INTO archived_orders SELECT * FROM orders WHERE ...; DELETE FROM orders WHERE ...; COMMIT;`
- Classic shapes that need this: move rows between tables (insert+delete), renumber or re-parent rows (update+update), replace a dataset (delete+insert), anything touching two tables that reference each other.
- In application scripts, use the explicit transaction API (`conn.transaction()`, `with session.begin():`, `DB.transaction do`), not a comment saying the steps are related.
- Add verification inside the transaction before committing: check affected row counts, and `ROLLBACK` if they're not what was predicted. A transaction you can still abort is the cheapest undo you will ever get.
- Know the boundary of this rule: huge bulk operations should be batched in many small transactions instead (one giant transaction is its own failure mode). The unit of atomicity is the logical fix, not the whole dataset.
- DDL caveat: some engines (MySQL) auto-commit on DDL statements, so mixing DDL into your transactional fix silently breaks atomicity. Keep schema changes and data fixes in separate units.

**Red flags that you're about to violate this:**

- "These statements run right after each other, nothing happens in between..."
- "Each statement is simple, what could fail..."
- "I'll run them one at a time so I can watch each succeed..."
- "Autocommit is the default, so it must be fine..."
- "Transactions are for application code, this is just a script..."
