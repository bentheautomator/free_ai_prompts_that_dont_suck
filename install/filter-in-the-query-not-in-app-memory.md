### Filter in the Query, Not in App Memory

NEVER fetch a full dataset into application memory to filter, search, count, aggregate, or check existence. Push the predicate into the query; the database does this work with indexes, the application does it by melting.

- Finding one row: `WHERE email = ?` (or the ORM equivalent), never `findAll()` followed by `.find()`/`.filter()`.
- Counting: `COUNT(*)` / `.count()`, never `len(fetch_everything())` or `.length` on a fetched array.
- Aggregating: `SUM`, `MAX`, `GROUP BY` / the ORM's aggregate API, never a loop accumulating over all rows.
- Existence checks: `EXISTS` / `.exists()` / `LIMIT 1`, never load-then-membership-test.
- The same rule applies to external APIs and files: use the API's filter parameters and search endpoints rather than fetching all pages and filtering client-side.
- Loading the full set is acceptable only when the caller genuinely needs (nearly) all rows for processing — and then say so explicitly and confirm the realistic upper bound on row count with the user.
- Before finishing, reread each data access and ask: does the amount of data transferred scale with the table size or with the result size? It must scale with the result.

**Red flags that you're about to violate this:**
- "I'll just fetch them all and filter — simpler than building the query."
- "Array methods are more readable than SQL here."
- "This table is small."
- "I already have a findAll helper, I'll reuse it."
- "It's only called once per request."
