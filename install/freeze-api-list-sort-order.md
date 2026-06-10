### Freeze API List Sort Order

NEVER change the order in which an existing list endpoint returns items — including "undocumented" or accidental orderings. Consumers infer order guarantees from observed behavior: they take the first element as latest, terminate sync loops on order, and display results as received. A changed order produces wrong data with a 200, never an error.

- Do not remove or alter ORDER BY clauses during query optimization, ORM migrations, or cleanup — even ones that look redundant. If the old query had no explicit ordering but returned a stable de facto order, add an explicit ORDER BY that *preserves* the observed order rather than leaving it to a new query plan.
- Changing databases, indexes, or pagination internals can silently reorder results. After such changes, compare result order on real data against the previous behavior.
- Alphabetical, relevance, or "more sensible" default orderings are new features: ship them behind a `sort=` parameter, and make the parameter's absence return the historical order.
- Within paginated endpoints, ordering is also what keeps pages consistent — changing it mid-flight breaks consumers walking pages, duplicating or skipping records across the boundary.
- If the user explicitly wants a new default order, note which consumer patterns break (first-element-as-latest, order-based sync termination, display order) and suggest the sort-param route with the default unchanged.

**Red flags that you're about to violate this:**
- "This ORDER BY isn't required by anything in the code — removing it speeds up the query."
- "Alphabetical order is more user-friendly for this list."
- "The API never documented an order, so no order is guaranteed."
- "The new query returns the same rows; order is an implementation detail."
- "Consumers should sort client-side if they care about order."
