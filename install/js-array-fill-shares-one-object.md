### JS Array Fill Shares One Object

NEVER initialize an array of objects (or array of arrays) with `.fill(someObjectOrArray)`. `fill` evaluates its argument once and copies the reference into every slot — mutating one element mutates them all.

- Right: `Array.from({length: n}, () => ({count: 0}))` — the callback runs per slot, producing n distinct objects.
- 2D arrays: `Array.from({length: rows}, () => new Array(cols).fill(0))`. Filling the inner array with a primitive is fine; primitives have no identity to share.
- Wrong: `new Array(rows).fill(new Array(cols).fill(0))` — one shared row; `grid[2][5] = 1` sets column 5 in every row.
- Wrong: `new Array(n).fill({})`, `.fill([])`, `.fill(new Thing())` — one shared instance.
- `.fill(0)`, `.fill(null)`, `.fill('x')` are fine: the rule is about reference types only.
- The same one-evaluation trap applies anywhere a "fresh" object is needed per use: `arr.map(() => makeDefault())` not `arr.map(x => DEFAULT)`; don't hand a module-level object out as a mutable default.
- When pre-sizing without `Array.from`: `[...Array(n)].map(() => ({}))` also works; bare `new Array(n).map(...)` does NOT (the holes are skipped and you get holes back).
- If elements are filled-then-immediately-overwritten with distinct values, `fill` as a placeholder is acceptable — but say so in a comment, because the next edit will mutate in place.

**Red flags that you're about to violate this:**

- "fill is the idiomatic way to initialize an array to a value."
- "I'll fill with an empty object and populate each slot later." (Populating via mutation hits the shared reference.)
- "This worked for the 1D zeros array, same pattern for the matrix."
- "It prints correctly, so the initialization is right."
- "JS arrays of arrays work like the nested list comprehension I'd write in Python."
