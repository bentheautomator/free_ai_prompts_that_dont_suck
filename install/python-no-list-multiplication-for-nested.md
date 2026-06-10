### Python No List Multiplication for Nested Structures

NEVER use list multiplication (`*`) to build a Python list whose elements are mutable (lists, dicts, sets, objects). Multiplication copies references, not objects, so all rows of `[[0]*cols]*rows` are the same list and writing one cell writes the whole column.

- Wrong: `grid = [[0] * cols] * rows` — every row aliases one list.
- Right: `grid = [[0] * cols for _ in range(rows)]` — the comprehension runs the inner expression per row, creating distinct lists.
- Wrong: `buckets = [[]] * n`, `slots = [{}] * n` — n references to one object.
- Right: `buckets = [[] for _ in range(n)]`.
- Wrong: `dict.fromkeys(keys, [])` — one shared list for every key. Right: `{k: [] for k in keys}` or `defaultdict(list)`.
- Multiplication is fine when elements are immutable: `[0] * n`, `[None] * n`, `["x"] * n` are all correct and preferred.
- Quick self-check before emitting `[X] * n`: if `X` evaluates to something mutable, rewrite as a comprehension.

**Red flags that you're about to violate this:**

- "`[[0]*cols]*rows` is the compact, Pythonic way to make a grid."
- "I printed the grid and it looks right, so the construction is correct."
- "The flat version `[0]*n` works, so nesting it must work too."
- "A comprehension with `for _ in range(...)` is uglier than multiplication."
- "fromkeys with a default list initializes every key in one call."
