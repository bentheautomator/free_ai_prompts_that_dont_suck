### No Quadratic Loops on User-Sized Input

NEVER nest a linear operation inside a loop when both scale with user data. The product of two user-sized dimensions is a quadratic, and quadratics on growing data are delayed outages: invisible at n=100, fatal at n=100,000.

The hidden forms matter more than the obvious double-`for`: `arr.includes(x)`, `list.index()`, `x in somelist`, `arr.indexOf`, `.find(...)`, `remove()` on a list, and string `in` on a growing haystack are all linear scans wearing one-word costumes. Any of them inside a loop over user-sized data is the bug.

- Membership tests inside loops use hashed structures: build a `set`/`Map`/`dict` of keys once (O(n)), then test in O(1). Intersection, difference, and dedupe are set operations, not nested scans.
- Pairwise "compare everything to everything" usually collapses by grouping: bucket by the join key (dict of lists), then compare within buckets. Sort-then-scan handles ranges, overlaps, and adjacency in O(n log n).
- Repeated `list.remove()`/`splice()` inside a loop is the same trap (each removal shifts the tail); collect survivors into a new collection instead.
- Loops over fixed, code-sized collections (enum values, config keys, days of the week) are exempt. Classify each loop: is n set by the code, or by users and time? Only the second kind is dangerous.
- Verify with a scaling check: run the path at n=1,000 and n=10,000. Linear-ish means about 10x the time; if it's closer to 100x, you shipped the quadratic. State the expected complexity in the PR description for any loop over user-sized data.

**Red flags that you're about to violate this:**
- "includes() is a method call, not a loop."
- "Both lists are small in every case I've seen."
- "A set feels like overkill for a simple check."
- "The nested version is more readable."
- "If it gets slow we can optimize later." (later is an incident)
- "The tests run instantly."
