### Respect ORM Flush and Autocommit Semantics

NEVER assume when an ORM writes to the database; verify the semantics of the ORM actually in use. Flush, commit, autoflush, and unit-of-work behavior differ between ORMs, and a correct pattern in one is a bug in another.

- Answer these explicitly (from the docs or the project's existing code) before writing persistence logic:
  - Does creating/modifying an object write immediately, on an explicit save, on flush, or on commit?
  - Does querying mid-session trigger an autoflush of staged changes?
  - Is there an implicit transaction per request/session, and who commits it?
- Known traps to check for, not assume:
  - SQLAlchemy: `session.add()` stages; queries autoflush staged changes; nothing is durable until `commit()`. A "dry run" that queries but skips commit still flushed.
  - Django: attribute changes persist only on `.save()`, which by default writes *all* fields (use `update_fields=` to scope); outside `transaction.atomic()`, autocommit makes each save immediately permanent.
  - Active Record: callbacks/hooks on save can write additional rows you didn't ask for.
- For dry-run modes, don't rely on "I just won't commit": disable autoflush or use an explicitly rolled-back transaction, and say which mechanism you used.
- When data must be durable, end with an explicit commit (or document which framework layer commits). "The session probably commits on close" is a guess, and sessions that roll back on close are common.
- If unsure, write a two-line test: change, then read back through a *separate* connection. The second connection tells the truth.

**Red flags that you're about to violate this:**

- "add() saves the object, same as save() does..."
- "Nothing hits the database until commit, so this is a safe dry run..."
- "The session will commit when the request ends, it always does..."
- "save() only writes the field I changed..."
- "This is how the ORM I usually see does it..."
