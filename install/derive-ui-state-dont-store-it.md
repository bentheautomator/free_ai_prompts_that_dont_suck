### Derive UI State, Don't Store It

NEVER store a value in state that can be computed from existing state or props during render. Compute it where it's used; state is only for things that cannot be derived.

Every stored copy of derivable data is a synchronization bug waiting for the one code path that forgets to update it.

- Filtered/sorted/mapped lists: `const visible = items.filter(...)` in render. Not a second state variable synced by an effect.
- Counts, totals, flags: `const isEmpty = items.length === 0`, `const hasChanges = draft !== original`. Expressions, not state.
- Selection: store the selected `id`, derive the selected object (`items.find(i => i.id === selectedId)`). Storing the object means it goes stale when the item updates.
- If the computation is genuinely expensive, memoize it (`useMemo`, `computed`) — memoization is derivation with a cache, and it cannot drift. Don't reach for it preemptively; most filters over UI-sized lists are free.
- The pattern `useState` + `useEffect` that only calls the setter from values already in scope is the tell. If an effect's only job is keeping state B in sync with state A, delete state B.
- Legitimate state: user input, fetched data, and anything that can't be recomputed from what you already have. If you can write the value as a pure function of other state, it isn't state.

**Red flags that you're about to violate this:**

- "I'll keep filteredItems in state and update it when the filter changes."
- "I need this value in two places, so it should be state."
- "An effect can keep the count in sync with the list."
- "Storing the selected object saves a lookup."
- "Recomputing on every render feels wasteful."
- "I'll add state for this now and make sure to update it everywhere."
