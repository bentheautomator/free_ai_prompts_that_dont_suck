### SQL NULL Needs IS, Not Equals

NEVER compare against NULL with `=` or `<>` in SQL — any comparison with NULL is UNKNOWN, and UNKNOWN rows are excluded by WHERE. Use `IS NULL` / `IS NOT NULL`.

- Wrong: `WHERE deleted_at = NULL` — matches zero rows unconditionally. Right: `WHERE deleted_at IS NULL`.
- Inequality filters exclude NULL rows: `WHERE status <> 'archived'` drops rows with NULL status. If NULLs should be included, say so: `WHERE status <> 'archived' OR status IS NULL`, or use `IS DISTINCT FROM 'archived'` where the dialect supports it.
- NEVER use `NOT IN` with a subquery whose column can be NULL — one NULL makes the entire predicate UNKNOWN and returns zero rows. Use `NOT EXISTS` (NULL-safe and usually better-planned) or filter NULLs in the subquery explicitly.
- NULL-safe equality where you genuinely mean "same, treating NULL as a value": standard `IS NOT DISTINCT FROM`, MySQL `<=>`. Don't emulate it with `COALESCE(col, 'sentinel')` unless the sentinel provably can't collide.
- Remember the aggregate asymmetry: `COUNT(*)` counts rows; `COUNT(col)` counts non-NULL values; `AVG(col)` divides by the non-NULL count. Pick deliberately.
- `NULL || 'text'` and arithmetic with NULL yield NULL — string-building and computed columns propagate absence; wrap with `COALESCE` when output must be non-NULL.
- In ORMs and query builders, check what `.where(field: nil)` style filters actually emit — most translate correctly, but raw-fragment escapes (`where("status <> ?")`) reintroduce the trap verbatim.

**Red flags that you're about to violate this:**

- "`= NULL` is the SQL spelling of `== null`."
- "`<> 'archived'` means everything that isn't archived." (NULL isn't 'not archived'; it's unknown.)
- "`NOT IN (subquery)` is the natural way to write this exclusion."
- "The query runs without errors, so the logic is right."
- "COUNT is COUNT; the column argument is cosmetic."
