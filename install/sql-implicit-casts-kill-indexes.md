### SQL Implicit Casts Kill Indexes

ALWAYS match the literal/parameter type to the column type in SQL predicates and joins. A type mismatch makes the database cast — often casting the *column*, which disables its index and can change matching semantics, all without any error.

- Check the schema before writing the predicate. VARCHAR column means quoted string: `WHERE phone = '5551234567'`, never `WHERE phone = 5551234567` (numeric literal forces a per-row cast of the column in MySQL: full scan, plus `'...abc'` suffixed strings matching).
- Numeric column means numeric parameter: passing `'42'` as a string usually casts the parameter (harmless), but dialect rules vary — don't rely on getting the lucky direction. Bind parameters with the correct type in application code rather than leaning on coercion.
- Never wrap an indexed column in a function or cast in WHERE/JOIN: `WHERE DATE(created_at) = ?`, `UPPER(email) = ?`, `CAST(id AS CHAR) = ?` all disqualify the plain index. Restructure to range predicates (`created_at >= '2026-06-01' AND created_at < '2026-06-02'`), store/compare normalized values, or create the matching functional index deliberately.
- Joins across tables: joining a VARCHAR key to an INT key (or mismatched collations/charsets in MySQL) silently de-indexes the join. Fix the schema or cast the side that isn't indexed for the lookup.
- Verify with the planner, not vibes: `EXPLAIN` the query and look for full scans and cast/collation notes on what should be an index lookup.
- When a query is mysteriously slow but correct, type mismatch is one of the first three suspects. Check it before adding an index that already exists.

**Red flags that you're about to violate this:**

- "The value is numeric, so I'll write it without quotes."
- "The database will cast it; same result either way."
- "The query returns the right rows, it's correct."
- "It's fast in my testing." (On the 200-row dev table.)
- "I'll just wrap the column in DATE() to compare days, it reads cleanly."
- "The ORM handles parameter types for me." (Until a raw fragment or a string-typed variable sneaks in.)
