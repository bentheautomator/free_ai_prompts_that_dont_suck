### JS Sort Numbers With a Comparator

NEVER call `.sort()` without a comparator unless the elements are strings and lexicographic order is genuinely what you want. JavaScript's default sort stringifies elements and compares code units: `[1, 5, 10].sort()` yields `[1, 10, 5]`.

- Numbers: `arr.sort((a, b) => a - b)` ascending, `(a, b) => b - a` descending. This also applies to numeric strings you intend to order numerically and to dates (`(a, b) => a - b` works on Date objects via valueOf).
- Objects: sort by an explicit key, `arr.sort((a, b) => a.price - b.price)`; for string keys use `a.name.localeCompare(b.name)`, not `<`/`>` on the raw strings, if human-facing order matters.
- Mutation: `sort()` reorders the array in place and returns the same reference. If the array came from props, state, a function argument, or a shared cache, sort a copy: `arr.toSorted(cmp)` (ES2023) or `[...arr].sort(cmp)`.
- `reverse()` has the same in-place behavior; use `toReversed()` or copy first under the same conditions.
- Comparator contract: return negative/zero/positive, and be consistent — returning a boolean (`(a, b) => a > b`) is a classic generated bug that produces incomplete, engine-dependent ordering.
- Beware `a - b` on values that may be `NaN` or `undefined`; filter or map them out before sorting.

**Red flags that you're about to violate this:**

- "It's a plain array of numbers — default sort handles the simple case."
- "My test data sorts correctly, so the comparator is optional here."
- "Returning `a > b` from the comparator is shorter and means the same thing."
- "sort() returns the array, so assigning it to a new const keeps the original intact."
- "This array is local, no one else can see the mutation." (Is it? It came in as a parameter.)
