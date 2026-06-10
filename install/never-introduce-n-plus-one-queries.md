### Never Introduce N+1 Queries

NEVER write code where the number of database queries scales with the number of rows processed. A query inside a loop — explicit or hidden behind an ORM relation — is an N+1 and must be restructured before it ships.

- Accessing a lazy-loaded relation inside a loop is a query per iteration. Use the ORM's eager loading (`select_related`/`prefetch_related`, `includes`, `JOIN FETCH`, `.Include()`, dataloader) on the original fetch instead.
- Replace per-item lookups with one batched query: collect the IDs, fetch with `WHERE id IN (...)`, and join in memory via a map. Same rule for `findById` in a `.map()` and for queries inside list comprehensions.
- Audit the loop body and everything it calls for hidden queries — serializers, `__str__`/`toString` methods, computed properties, and template rendering are classic offenders.
- Verify by counting queries, not by reading code: enable query logging or use the test framework's query counter, run the code path, and confirm the count is constant regardless of row count. With 10 rows and with 200 rows, the number of queries should be identical.
- Tests pass with small fixtures, so passing tests prove nothing here. The query count is the test.

**Red flags that you're about to violate this:**
- "The ORM handles relations efficiently, that's its job."
- "It's just an attribute access, not a query."
- "This list will never be large."
- "It works fine when I run it." (against ten rows)
- "Eager loading makes the code more complicated than it needs to be."
