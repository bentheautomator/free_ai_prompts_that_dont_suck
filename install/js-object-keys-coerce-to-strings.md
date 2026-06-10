### JS Object Keys Coerce to Strings

NEVER use a plain object as a dictionary when the keys are anything other than strings you control. Object keys are coerced to strings: `obj[1] === obj["1"]`, and any object key becomes `"[object Object]"`, collapsing all entries into one.

- Non-string keys (numbers you must keep distinct from strings, objects, DOM nodes, class instances): use `Map`. `Map` compares keys by identity/SameValueZero with no coercion: `map.get(1)` and `map.get("1")` are different entries.
- Wrong: `const seen = {}; seen[node] = true` — every node coerces to `"[object Object]"`. Right: `const seen = new Set()` or `new Map()`.
- Keying by entity: `cache[user]` is the collapsed-cache bug. Use `cache.set(user, value)` (identity) or key by a real scalar: `cache[user.id]`.
- If you key an object by numeric ids, know that `Object.keys` returns strings (`"42"`, not `42`) and integer-like keys iterate in ascending numeric order regardless of insertion order. If either fact would surprise the consuming code, use a `Map` (which preserves insertion order and key types).
- `WeakMap`/`WeakSet` when object keys should not prevent garbage collection (caches, metadata side-tables).
- Plain objects remain fine for fixed, known string keys (config, JSON-shaped records). The rule is about dynamic dictionaries.

**Red flags that you're about to violate this:**

- "An object literal is the lightweight way to build a lookup table."
- "The keys are user ids, numbers work fine as keys." (They become strings; fine until someone compares.)
- "I'll index by the object itself, it's unique."
- "Map is overkill, this is just a small cache."
- "Insertion order will be preserved like in Python dicts."
- "JSON.stringify the key and it's effectively the same thing." (Stringify is order-sensitive and slow; say so if you truly need it.)
