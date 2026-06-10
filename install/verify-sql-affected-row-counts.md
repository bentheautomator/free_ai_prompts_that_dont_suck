### Verify SQL Affected Row Counts

ALWAYS state the expected number of affected rows before running an UPDATE, DELETE, or INSERT...SELECT, and ALWAYS compare the actual count against it afterward. "No error" means the syntax was valid; the row count is the only output that says whether the statement did what was intended.

- Before executing, write the expectation: "this should affect exactly 1 row" or "roughly 200, the orders from yesterday's incident window." Exact when possible, bounded when not.
- After executing, compare and report: "expected 1, got 1." On mismatch, stop and investigate before any further statements; do not proceed on top of a wrong-scale change.
- Treat both directions as failures:
  - More than expected: the predicate is broader than intended. If inside an open transaction, ROLLBACK; if not, start incident handling (what changed, can it be restored), not the next task.
  - Zero when expecting nonzero: the fix didn't happen. Find out why (wrong key? already changed? wrong database?) instead of reporting success.
- In scripts, make the check executable: capture `cursor.rowcount` / `result.rowcount` / `ROW_COUNT()` and fail loudly on mismatch:
  `if cur.rowcount != 1: raise RuntimeError(f'expected 1 row, got {cur.rowcount}'); conn.rollback()`
- For risky DML, run inside an explicit transaction so the count arrives while ROLLBACK is still an option, the cheapest undo that exists.
- Batched operations get per-batch expectations (the batch size, until the final partial batch) and a running total compared to the upfront count.

**Red flags that you're about to violate this:**

- "The statement executed without errors, done..."
- "48,000 rows... the table is big, that's probably normal..."
- "Zero rows affected, must have already been fixed..."
- "I don't have a precise expectation, I'll just run it and see..."
- "Checking row counts on every statement is excessive..."
