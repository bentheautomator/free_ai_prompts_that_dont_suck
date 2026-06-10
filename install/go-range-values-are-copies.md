### Go Range Values Are Copies

NEVER mutate the value variable of a Go `range` loop expecting the collection to change — it is a copy. Mutations must go through the index or a pointer to the element.

- Wrong: `for _, o := range orders { o.Status = "done" }` — modifies copies; `orders` is unchanged. Right: `for i := range orders { orders[i].Status = "done" }`.
- Slices of pointers (`[]*Order`) are the exception: the copied value is a pointer to the shared struct, so `o.Status = "done"` works. Know which one you're holding before choosing the pattern.
- Collecting pointers: `out = append(out, &item)` aliases the loop variable. Pre-Go-1.22 every pointer ends up at the last element; even on 1.22+, prefer `&items[i]` or copy explicitly (`item := item` pre-1.22) so the code doesn't depend on toolchain version.
- `&items[i]` is only stable while the backing array isn't reallocated — don't take element pointers from a slice you're still appending to.
- Maps: `range` over a map yields copied values too, and map values aren't addressable; to mutate, write the whole value back (`m[k] = v`) or store pointers in the map.
- Large structs: the per-iteration copy is also a performance cost; `for i := range` avoids it.
- Don't assume Go 1.22 loop-variable semantics fixed all of this: it fixed variable reuse across iterations, not the fact that the value is a copy.

**Red flags that you're about to violate this:**

- "I set the field inside the loop, so the slice is updated."
- "The print statement shows the new value, the mutation worked." (On the copy.)
- "`&item` gives me a pointer to the element."
- "Go 1.22 fixed the range variable problem, this pattern is safe now."
- "It's the same loop I'd write in Python."
