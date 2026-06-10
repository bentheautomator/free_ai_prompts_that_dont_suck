### Go Nil Map Writes Panic

NEVER write to a Go map without ensuring it was initialized. Nil maps read fine (`m[k]` gives the zero value, `len` is 0, `range` is empty) but any write panics at runtime — so the bug hides behind every read-only code path.

- Initialize at declaration: `m := map[string]int{}` or `make(map[string]int)`, not `var m map[string]int`, unless the map is provably never written.
- Structs with map fields: initialize in a constructor (`func NewCache() *Cache { return &Cache{entries: make(map[string]Entry)} }`) and route creation through it. A struct literal that omits a map field leaves it nil.
- Deserialization: `json.Unmarshal` leaves a map field nil when the key is absent from the input. If code writes to that map afterward, nil-check and `make` it first.
- Lazy-init guard where construction can't be controlled: `if m == nil { m = make(...) }` before the write — but prefer fixing the constructor.
- Nested maps: `m[a][b] = v` needs the inner map to exist. Initialize on first use: `if m[a] == nil { m[a] = make(map[K]V) }`.
- Do NOT port this caution to slices and conclude `append` needs a non-nil slice — `append(nilSlice, x)` is correct, idiomatic Go. The asymmetry is the trap: slices forgive, maps don't.
- Deleting from a nil map is a no-op (legal); only writes panic. Don't add nil-checks to read/delete paths that don't need them.

**Red flags that you're about to violate this:**

- "`var m map[string]int` is the cleaner way to declare it."
- "All the tests pass, the map is clearly initialized." (Tests may only exercise reads.)
- "The struct literal sets the fields that matter."
- "Unmarshal will populate the map." (Only if the key is present.)
- "It works like a nil slice — Go zero values are usable."
