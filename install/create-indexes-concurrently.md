### Create Indexes Concurrently on Live Tables

NEVER add or drop an index on a production-sized table with the default locking form. Plain `CREATE INDEX` blocks all writes to the table for the entire build, which on large tables means minutes of write outage.

- Postgres: use `CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);` and `DROP INDEX CONCURRENTLY` for removals.
- `CONCURRENTLY` cannot run inside a transaction. Configure the migration accordingly: `disable_ddl_transaction!` (Rails), `atomic = False` (Django), `transaction: false` in the migration tool's terms. A concurrent index migration without this setting will simply fail.
- Handle the failure mode: if a concurrent build dies, it leaves an INVALID index. Make the migration idempotent: drop the invalid index if present, then create.
- MySQL/InnoDB: most secondary index adds are online by default (`ALGORITHM=INPLACE, LOCK=NONE`); state the algorithm explicitly so a silent fallback to a locking rebuild fails loudly instead.
- Before writing the migration, ask or check how big the table is. On genuinely small tables (thousands of rows) the plain form is fine; say that you checked.
- This is about live tables. Brand-new tables created in the same migration can take plain indexes freely.

**Red flags that you're about to violate this:**

- "CREATE INDEX is a standard, safe operation..."
- "The ORM helper generated it this way..."
- "CONCURRENTLY has weird transaction issues, simpler to skip it..."
- "Index creation is fast, the lock won't matter..."
- "I'll use the same pattern as the existing old migrations..."
