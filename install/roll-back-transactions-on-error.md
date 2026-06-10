### Roll Back Transactions on Error

Inside a transaction, any error means the whole transaction rolls back. NEVER catch an exception mid-transaction and continue to commit — partial units of work must not become permanent.

- The transaction is the try scope: one try around the whole unit of work, with `except: rollback(); raise` — not per-statement catches that fall through to commit
- Never call `commit()` in a `finally` block or after a swallowed exception; commit belongs only on the path where every statement succeeded
- Prefer the language's transactional scope constructs, which encode commit-on-success/rollback-on-error correctly: `with session.begin():` (SQLAlchemy), `transaction.atomic()` (Django), `BEGIN/COMMIT` wrappers in your DB library, `TransactionScope` in .NET — over hand-wired commit/rollback
- If you catch an error inside a transaction to handle it (e.g. fall back to an alternate write), the handling must stay transaction-aware: either the transaction is still valid in your database (it isn't in PostgreSQL after an error, without savepoints), or you roll back / roll back to a savepoint first
- Always wire the error path: an opened transaction must reach exactly one of commit or rollback on every code path, including early returns — leaked open transactions hold locks and poison pooled connections
- Side effects that can't roll back (HTTP calls, emails, file writes) don't belong inside the transaction; do them after commit, or design compensation for them

**Red flags that you're about to violate this:**
- "I'll catch the error on this statement so the rest of the transaction completes..."
- "Commit in finally guarantees we never lose the work..."
- "Logging the failed update is enough; the other writes are fine..."
- "Rollback throws away the successful statements, which seems wasteful..."
- "I'll handle the constraint violation inline and keep going..."
