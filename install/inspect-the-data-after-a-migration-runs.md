### Inspect the Data After a Migration Runs

NEVER declare a migration, backfill, or bulk data script successful based on a clean exit. The script not crashing is not the goal; the data being in the intended new state is. Inspect the data.

The core problem: "ran without errors" is compatible with zero rows matched, nulls written, records skipped, and values misplaced. Only the data itself can confirm the transformation happened, happened to everything, and happened correctly.

- Before running, record the expectation: how many rows should be affected, and what should a transformed record look like? An expectation written first cannot be retrofitted to whatever happened.
- After running, count: rows affected vs rows expected. Zero affected on a script meant to change thousands is a failure with exit code 0. "Approximately right" counts deserve an explanation, not a shrug.
- Sample actual records — several, not one — and check the transformed values are correct, not merely present. A populated column full of empty strings passes existence checks and fails the point.
- Hunt the leftovers: query for rows still in the old state. The skipped 5% with unusual shapes is the classic silent failure, and only a "what didn't transform?" query finds it.
- Check what shouldn't have changed: total row counts (no duplication, no loss), untouched columns, adjacent tables.
- Report with the receipts: "expected ~12,400 updates; 12,397 affected; 3 remaining in old state, listed; 5 sampled records correct." That sentence cannot be written without doing the work — which is the point.

**Red flags that you're about to violate this:**
- "It completed with no errors, so the data's migrated..."
- "The framework would have raised if something went wrong..."
- "I checked one row and it looked right..."
- "Counting affected rows is overkill for a simple UPDATE..."
- "The skipped records were probably edge cases that don't matter..."
- "It worked on the test database, and prod data is the same shape..."
