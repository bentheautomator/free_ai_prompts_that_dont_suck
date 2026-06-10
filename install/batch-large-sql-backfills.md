### Batch Large SQL Backfills

NEVER run a backfill, bulk UPDATE, or bulk DELETE as a single statement in a single transaction without first knowing the row count. Above roughly 10,000 affected rows, batch it.

One giant data-change transaction holds locks for its entire runtime, blocks concurrent writes, bloats the WAL/undo log, lags replicas, and loses all progress if interrupted.

- Before writing the statement, check scale: `SELECT count(*) FROM orders WHERE shipped_at IS NOT NULL AND status IS NULL;` State the number out loud in your response.
- Batch by primary key range or with a LIMIT loop, committing each batch:
  `UPDATE orders SET status = 'complete' WHERE id IN (SELECT id FROM orders WHERE shipped_at IS NOT NULL AND status IS NULL LIMIT 5000);`
  Repeat until 0 rows affected.
- Make the loop resumable: the WHERE clause must exclude already-processed rows (`status IS NULL` above), so a crash mid-run resumes instead of restarting.
- Sleep briefly between batches (100-500ms) to let replication catch up and other transactions breathe.
- Bulk DELETEs follow the same rule. For deleting most of a table, prefer copying survivors to a new table or dropping a partition over a giant DELETE.
- Never wrap the whole batched loop in one outer transaction; that defeats the entire point.

**Red flags that you're about to violate this:**

- "One UPDATE statement is the cleanest way to do this..."
- "I don't know how big the table is, but the query is correct..."
- "A single transaction is safer because it's atomic..."
- "Batching adds complexity the user didn't ask for..."
- "It worked instantly on my test data..."
