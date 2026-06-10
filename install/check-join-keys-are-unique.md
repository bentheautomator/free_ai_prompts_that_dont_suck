### Check Join Keys Are Unique

NEVER merge on a key you haven't verified is unique on the side that's supposed to be unique. A duplicate key turns a join into a row multiplier, and every aggregate downstream inherits the inflation silently.

- In pandas, declare the expected relationship on every merge: `orders.merge(customers, on='customer_id', validate='many_to_one')`. It's one argument and it raises the moment the assumption breaks. Use `one_to_one` where that's the contract.
- Where `validate=` isn't available (SQL, Spark), check explicitly before joining: `SELECT key, COUNT(*) FROM dim GROUP BY key HAVING COUNT(*) > 1` or `assert not customers['customer_id'].duplicated().any()`.
- Assert the row count after the join matches intent: a many-to-one enrichment must satisfy `len(result) == len(orders)` (with `how='left'`). Write that assert. Fan-out you wanted should be stated; fan-out you didn't is a bug.
- Watch for NULL keys: rows with null join keys silently drop on inner joins and silently survive on left joins — decide which you want and check `df[key].isna().sum()` first.
- When duplicates are legitimate (history tables, SCD), don't merge raw — resolve to the intended grain first (`drop_duplicates(subset=key, keep='last')` after a deliberate sort, or filter to current records), and say which record wins and why.
- Never "fix" inflated results with a `drop_duplicates()` after the join; that hides the modeling error and keeps an arbitrary row. Fix the grain before joining.

**Red flags that you're about to violate this:**

- "customer_id is obviously unique in the customers table..."
- "The merge ran fine, shapes look reasonable..."
- "I'll dedupe afterward if the numbers look off..."
- "validate= is extra noise on a simple join..."
- "It's a dimension table, dimension tables don't have dupes..."
