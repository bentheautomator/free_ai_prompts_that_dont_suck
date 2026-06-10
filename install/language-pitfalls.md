### Integer Division Differs by Language

NEVER port division or modulo between languages operator-for-operator without checking semantics for (a) integer vs float division and (b) behavior on negative operands. The operators look identical and aren't.

- Division type: `7/2` is `3.5` in Python 3 and JS, `3` in Go/C/Java/Rust and most SQLs when both operands are integers. When porting, decide which result the algorithm needs and make it explicit: `//` or `math.floor` in Python, `Math.floor`/`Math.trunc` in JS, plain `/` on ints elsewhere.
- Negative rounding direction: Python `//` floors (`-7 // 2 == -4`); Go/C/Java/Rust/JS truncate toward zero (`-3`). Different answers whenever signs differ.
- Modulo sign: Python `%` returns the divisor's sign (`-7 % 2 == 1`); Go/C/Java/JS return the dividend's sign (`-7 % 2 == -1`). Rust has both (`%` truncates; `rem_euclid` floors). SQL dialects vary.
- Circular indexing with possibly-negative values: `arr[i % n]` is only safe under floor-mod. Portable form: `((i % n) + n) % n`, or the language's euclidean-mod function. Use it whenever `i` can be negative.
- Bucketing/windowing (timestamps into intervals, ids into shards): pick floor semantics explicitly so values below the origin land in the correct lower bucket, and implement it per the target language, not per the source syntax.
- JS extra: `%` works on floats too (`5.5 % 2 === 1.5`) and `x | 0`-style integer tricks break beyond 32 bits — don't use bitwise ops as integer division.
- When writing the port, add a test with a negative operand. It is the single test that distinguishes every convention above.

**Red flags that you're about to violate this:**

- "Modulo is modulo, the operator is the same in both languages."
- "I translated it line by line, the logic is unchanged."
- "Indices here are always positive." (Deltas, offsets, and pre-epoch timestamps would like a word.)
- "The tests pass." (With all-positive fixtures.)
- "I'll round the division at the end; direction doesn't matter."

### Locale Breaks String Casing

ALWAYS use locale-independent casing and formatting for machine-facing strings (protocol tokens, headers, extensions, enum/config keys, serialized numbers). Default casing and formatting follow the process locale, so the same code produces different bytes on different machines — the Turkish-İ bug.

- Java: `toLowerCase(Locale.ROOT)` / `toUpperCase(Locale.ROOT)`; `String.format(Locale.ROOT, ...)` for serialized numbers. Bare `toLowerCase()` on a token is a latent bug.
- .NET: `ToLowerInvariant()` / `ToUpperInvariant()`; compare with `StringComparison.OrdinalIgnoreCase`; format/parse with `CultureInfo.InvariantCulture`.
- Python/Go/JS default casing is not locale-driven (safer default), but JS has `toLocaleLowerCase` and Python has locale-aware formatting — don't reach for those for machine strings. For Unicode-correct case-insensitive matching of *human* text, use case folding (`str.casefold()` in Python), not lowercase.
- Case-insensitive token comparison shouldn't case-convert at all where an ordinal-ignore-case comparison exists (`equalsIgnoreCase` in Java is locale-safe for this; `strings.EqualFold` in Go).
- Serializing numbers and dates for files, APIs, and logs: always invariant/ROOT locale. `"1,5"` where a parser expects `"1.5"` is this bug in formatting clothes.
- Locale-aware casing and formatting are correct for text *displayed to users* — that's what the locale-sensitive APIs are for. The rule is about strings consumed by software.
- Don't fix this by setting the process default locale to English: that breaks actual localization and is a global mutable setting. Fix the call sites.

**Red flags that you're about to violate this:**

- "toLowerCase is a pure function of the string."
- "It passes on CI, casing is deterministic."
- "Nobody runs servers in a Turkish locale." (JVMs and desktops inherit OS locales everywhere your users are.)
- "I'll normalize with toUpperCase before comparing — uppercase is safe." (Turkish uppercases i to İ.)
- "I'll just set the default locale to en-US at startup."
- "%f formatting always uses a decimal point."

### Regex Dialects Are Not Portable

NEVER copy a regex between languages or tools as if it were plain data. Regex dialects differ in anchoring, escapes, character-class semantics, and supported features; a ported pattern can compile and silently match differently.

- On every port, re-verify three things: anchoring (Python `re.match` anchors at start, `re.fullmatch` both ends, JS/Go search anywhere — add explicit `^...$` or `\A...\z` per the target's rules), flags (how the target spells case-insensitive, multiline, dotall), and feature support.
- For validation, prefer explicit full anchors in the pattern itself rather than relying on the host function's anchoring behavior — it makes the intent portable.
- `$` is not "end of string" everywhere: in several engines it also matches before a final newline; use `\z` (or the target's equivalent) when trailing-newline acceptance matters, e.g. validating user input.
- Feature gaps: Go (RE2), POSIX `grep`/`sed`, and RE2-based services have no lookahead, lookbehind, or backreferences. Do not approximate such patterns — restructure the logic (multiple matches plus code) and say so.
- `\d`, `\w`, `\s` are Unicode-aware in some engines (Python 3) and ASCII in others (Go, JS without flags). If you mean `[0-9]`, write `[0-9]`.
- Shell contexts mangle patterns before the engine sees them: backslashes and `$` inside double quotes, BRE vs ERE in `grep` vs `grep -E`, `sed`'s escaping of `+` and `?` in BRE. Test the pattern *in* the shell context, not just in a regex playground set to PCRE.
- After porting, run the target-language pattern against a small fixture set including the edge cases: empty string, trailing newline, multiline input, non-ASCII digits/letters.

**Red flags that you're about to violate this:**

- "A regex is a regex; I'll reuse the one from the Python service."
- "It compiles in the new language, so the port worked."
- "re.match and string.match do the same thing."
- "I'll emulate the lookbehind with something close enough."
- "The playground says it matches." (The playground is running a different engine than your code.)

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

### Go Shadowed err Swallows Failures

NEVER use `:=` in an inner scope when it re-declares a variable (especially `err` or a result) that an enclosing scope declares and later uses. The inner block gets fresh variables; the outer ones silently keep their old values — typically a nil `err` and a zero result.

- Wrong: outer `var data []byte; var err error`, then inside a branch `data, err := load(path)` — outer `data`/`err` untouched; function returns empty data, nil error. Right: `data, err = load(path)` (plain `=`).
- When a call returns one new variable plus an existing `err`, `:=` only works without shadowing if at least one variable on the left is new *and you're in the same scope*. Inside a nested block, declare the new variable first (`var n int`) and use `=`, or restructure.
- The safest structure avoids the situation: handle errors immediately and return early (`x, err := call(); if err != nil { return ... }`) instead of accumulating into long-lived outer `err`/result variables that inner blocks must assign.
- Named return values + `defer` that reads `err`: any inner `err :=` disconnects the deferred check from the actual failure. Inside such functions, be strict about `=` vs `:=`.
- After writing or moving code into a new `if`/`for`/`switch` block, re-check every `:=` inside it against enclosing declarations — wrapping code in a block is how correct `=` becomes shadowing `:=`.
- Enable shadow analysis in CI where practical: `go vet -vettool` with the `shadow` analyzer catches most of these mechanically.

**Red flags that you're about to violate this:**

- "`x, err := call()` is the idiomatic form, always."
- "The error is checked right below the call, this is handled."
- "I'm just wrapping these lines in an if-block, nothing changes."
- "The compiler would complain if I redeclared a variable." (Not across scopes — that's shadowing, and it's legal.)
- "The deferred cleanup will catch any error before returning."

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

### JS Falsy Zero Breaks Input Checks

NEVER use bare truthiness (`if (!x)`, `x || default`) to test whether a JavaScript value is present when `0`, `""`, `false`, or `NaN` are valid values for it. Truthiness conflates "absent" with eight different legitimate values.

- Wrong: `if (!amount) throw new Error("amount required")` — rejects a valid `amount` of `0`.
- Right: `if (amount === undefined || amount === null)` or `if (amount == null)` (the one acceptable use of `==`: it matches exactly `null` and `undefined`).
- Wrong: `const limit = options.limit || 100` — an explicit `limit: 0` becomes `100`.
- Right: `const limit = options.limit ?? 100` — nullish coalescing only falls through on `null`/`undefined`.
- Wrong: `enabled = flags.enabled || true` — this can never be `false`. Use `??`.
- Bare truthiness is fine when the value is genuinely binary-shaped: objects, arrays, class instances, or strings where empty means absent by the function's own contract. State that contract in a comment if you rely on it.
- When checking for a property's existence vs. its value, use `'key' in obj` or `obj.key !== undefined`, not `obj.key` alone.
- For numbers that must be real numbers, check `Number.isFinite(x)`, not `x` or `!isNaN(x)`.

**Red flags that you're about to violate this:**

- "`if (!x)` is the idiomatic way to check for missing values."
- "Nobody would ever pass zero here."
- "`||` with a default is shorter and reads better than `??`."
- "The existing code uses `!x` checks, so I'll match the style."
- "Empty string is basically the same as not provided."
- "I'll keep the guard simple; validation happens elsewhere anyway."

### JS No Float Money Math

NEVER do arithmetic on money as floating-point decimals in JavaScript. Every JS number is an IEEE 754 double; `0.1 + 0.2 !== 0.3`, and repeated operations accumulate drift that corrupts totals by real cents.

- Store and compute money in integer minor units (cents, satoshi, etc.): `1999` for $19.99. Integers are exact up to `Number.MAX_SAFE_INTEGER` (9 quadrillion cents).
- Wrong: `total += item.price * item.qty` with `price = 19.99`. Right: `totalCents += item.priceCents * item.qty`.
- Convert to decimal display only at the last moment: `(cents / 100).toFixed(2)` for display, or better, `Intl.NumberFormat` with a currency option.
- Percentages and division create fractions of a cent. Round explicitly at a defined point with a defined mode (`Math.round`, banker's rounding if the domain requires it) — never let `toFixed` be the accidental rounding policy, and never round twice.
- For high-precision or multi-currency math, use a decimal library or `BigInt` minor units; do not hand-roll with floats "carefully."
- Never compare computed money values with `===` on floats. If floats are already in the codebase and can't be removed, compare against an epsilon and say so in a comment.
- Parsing user input: parse `"19.99"` into integer cents directly (split on the separator); `parseFloat` then `* 100` yields `1998.9999999999998` for some inputs.

**Red flags that you're about to violate this:**

- "It's just two decimal places, doubles handle that fine."
- "I'll `toFixed(2)` at the end, that cleans up any drift."
- "The existing schema stores price as a float, so I'll keep computing in floats."
- "Multiplying by 100 converts it to cents safely."
- "This is an internal estimate, the exact cents don't matter." (It will be reused for billing.)
- "Adding a decimal library is overkill for one calculation."

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

### JS Optional Chaining Is Not Error Handling

Use `?.` ONLY where absence is an expected, valid state you are deliberately handling. NEVER use it to suppress a crash on data that is supposed to be there — that converts a located TypeError into silent `undefined` propagating through the system.

- Before writing `?.`, answer: per the data contract, can this legitimately be missing? If yes, `?.` plus an explicit fallback or branch. If no, access it plainly and let it throw, or validate at the boundary and fail with a real error.
- Wrong: `const city = order?.customer?.address?.city ?? ''` when orders always have customers — a broken join now ships blank labels. Right: `order.customer.address` (crash at the bug) or boundary validation that rejects the malformed order loudly.
- `??`/fallback values deserve the same scrutiny: a default is a decision about business behavior, not a crash-prevention tool.
- `callback?.()` silently skips required wiring. Only use it for genuinely optional hooks.
- Do not chain `?.` after the first one reflexively: in `a?.b.c`, if `a` exists then `b` is being asserted to exist — make that assertion match the contract instead of autocompleting `?.` onto every link.
- When unsure whether a field is optional, do not guess with `?.`. Check the type/schema/API docs, or validate explicitly and throw a descriptive error.
- TypeScript: fix the type or narrow it; using `?.` to silence a type error has the same downstream cost.

**Red flags that you're about to violate this:**

- "I'll add `?.` everywhere to be safe."
- "Better to render nothing than to crash."
- "I'm not sure if this field is optional, `?.` covers both cases."
- "The linter/types complained, `?.` makes it green."
- "This fixes the reported TypeError." (It hides it. The data is still wrong.)
- "Defensive coding is good practice."

### JS Parse Numbers Deliberately

ALWAYS choose the number-parsing function by intent, validate the result, and never call `parseInt` without an explicit radix. JavaScript's parsers disagree on whitespace, empty strings, trailing garbage, and prefixes, and most failures return a plausible number rather than throwing.

- Default for "this string should be exactly one number": `Number(str)` — it rejects trailing garbage (`Number("12px")` is `NaN`).
- Wrong: trusting `Number("")` — it returns `0`, not `NaN`. Check for empty/whitespace-only input first, or use a regex guard like `/^-?\d+$/`.
- `parseInt(str, 10)` only when you deliberately want prefix-parsing (e.g. `"12px"` to `12`), and say so in a comment. Never omit the radix.
- Never call `parseInt` on a number: `parseInt(0.0000005)` returns `5` via exponential stringification. Use `Math.trunc`/`Math.floor` to truncate numbers.
- ALWAYS check the result before using it: `if (!Number.isFinite(n)) ...`. Not `isNaN(n)` (it coerces) and not `n === NaN` (always false).
- For integers from user input, follow up with `Number.isSafeInteger(n)` when the value will index, count, or be persisted.
- Strip or reject locale formatting (`"1,200"`, `"1.200,50"`) explicitly — no parser handles it; `parseInt("1,200", 10)` returns `1`.

**Red flags that you're about to violate this:**

- "`parseInt(x)` is the standard way to read a number from a string."
- "The input comes from our own form, it'll always be clean digits."
- "If the parse fails it'll be NaN and the comparison will just be false, which is safe."
- "Adding a radix argument is redundant on modern runtimes."
- "I'll coerce with `+x`, it's the terse idiom everyone uses."

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

### JS Strict Equality Only

Use `===` and `!==` for every comparison in JavaScript and TypeScript. The loose operators (`==`, `!=`) coerce types before comparing, producing results like `"" == 0` (true), `"0" == false` (true), and `null == 0` (false) that change behavior the moment a value's type drifts.

- Wrong: `if (status == 200)`, `if (input != "")` — use `===` / `!==`.
- One sanctioned exception: `value == null` is the standard idiom for "null or undefined" in one check. If a codebase uses it, keep it; if you write it, you may instead write the explicit `value === null || value === undefined`. NEVER mechanically rewrite `== null` to `=== null` — that drops the `undefined` case and changes behavior.
- Don't rely on coercion to compare across types. If one side is a string and the other a number, convert explicitly first (`Number(param)`, `String(id)`) and then use `===`.
- `NaN === NaN` is false; test with `Number.isNaN(x)`, never with equality.
- For objects and arrays, neither operator compares contents — both compare references. Use a deep-equality helper when you mean contents.
- In TypeScript, `===` plus narrowed types catches at compile time what `==` hides at runtime; don't silence the compiler with `as any` to make a loose comparison typecheck.

**Red flags that you're about to violate this:**

- "`==` handles the string-vs-number case for me automatically."
- "I'll normalize this `== null` to `=== null` while I'm here."
- "The query param is always a number in practice, so coercion is harmless."
- "Two equals signs compare values in every other language I know."
- "This comparison has worked in production for years, so the operator is fine."

### JS typeof null Is Object

ALWAYS exclude `null` explicitly when using `typeof x === 'object'` — `typeof null` is `"object"`, so the bare check admits `null` and the crash happens at the later property access instead of at the guard.

- Plain object check: `x !== null && typeof x === 'object'`. In TypeScript, this is also what narrows the type correctly.
- Wrong: `if (typeof payload === 'object') { handle(payload.data) }` — throws on `null` payloads.
- Array vs object: `typeof` cannot tell them apart; use `Array.isArray(x)` for arrays, and check it before the generic object branch when both are possible inputs.
- "Is a valid number": `typeof x === 'number'` admits `NaN` and `Infinity`. Use `Number.isFinite(x)` when you mean a usable number.
- `typeof fn === 'function'` is fine and is the one reliable structural `typeof` check.
- Do not "simplify" `x !== null && typeof x === 'object'` to a truthiness check on `x` alone, and do not reorder it so the `typeof` runs first in a way that lets a later refactor drop the null clause.
- When the real question is "can I read properties off this," prefer validating the specific shape (`x?.data !== undefined`, a schema validator, or a TS type guard) over duck-typed `typeof` chains.

**Red flags that you're about to violate this:**

- "`typeof x === 'object'` is the standard way to check for an object."
- "This value comes from JSON.parse, so it's definitely an object." (JSON `null` parses to `null`.)
- "The null case can't happen here."
- "I'll tidy this guard up by dropping the redundant null check."
- "typeof says it's a number, so it's safe to do arithmetic with." (NaN says hello.)

### JSON Big Numbers Lose Precision

NEVER represent 64-bit integers (ids, snowflakes, nanosecond timestamps, cursors) as JSON numbers when any consumer might parse them as doubles. Above 2^53 (about 9.0e15), doubles silently round: `9007199254740993` parses as `...992`, and the corrupted id round-trips without error.

- Serialize 64-bit ids as JSON strings: `{"id": "9007199254740993"}`. APIs that must stay compatible can send both (`id` numeric legacy, `id_str` canonical) — consumers must use the string.
- In JavaScript/TypeScript, type ids as `string`. Never `parseInt`/`Number()` an id "to clean it up" — ids are opaque tokens; they're compared, stored, and passed, never used in arithmetic.
- If you must parse JSON containing large numerics you don't control, use a parser with bigint/raw-number support (`JSON.parse` reviver with source access where available, or a lossless-JSON library); stock `JSON.parse` has already destroyed the value by the time you see it.
- Server side: declare ids as strings in the schema (OpenAPI `type: string`), even when the database column is BIGINT. Convert at the storage boundary, not in transit.
- Proxies, loggers, and tools that parse-then-restringify JSON corrupt large numbers in payloads they merely forward — treat any parse step in the pipeline as a consumer.
- Floats in JSON have the cousin problem (decimal fractions are approximations); money amounts follow the same rule: strings or integer minor units, not JSON decimals.
- Small bounded integers (counts, ports, enum-ish codes) remain plain JSON numbers. The rule is about 64-bit-range values and opaque identifiers.

**Red flags that you're about to violate this:**

- "The id is an integer, so the JSON type should be a number."
- "I'll parse the id to a number for the comparison."
- "Our ids are nowhere near 2^53." (Snowflake ids passed it years ago; yours are timestamp-prefixed too.)
- "The API docs show the id without quotes."
- "I'm just reformatting the JSON, not changing values." (Your formatter parses it first.)
- "TypeScript says number, so number is correct."

### Python Aware Datetimes Only

ALWAYS create timezone-aware datetimes in Python. NEVER use bare `datetime.now()` or `datetime.utcnow()` — both return naive objects that mean different instants on different machines and that cannot be safely compared, serialized, or converted.

- Right: `datetime.now(timezone.utc)` (from `datetime import datetime, timezone`) for "the current instant."
- Wrong: `datetime.utcnow()` — correct UTC value, but naive, so the UTC-ness is lost the moment it leaves the variable. It is deprecated; do not generate it even though training examples are full of it.
- Wrong: `datetime.fromtimestamp(ts)` — uses the server's local zone; use `datetime.fromtimestamp(ts, tz=timezone.utc)`.
- When parsing, attach the zone: `datetime.fromisoformat(s)` keeps an offset if the string has one; if the string is naive, you must decide and document what zone it represents — don't guess silently.
- Store and compute in UTC; convert to local time only at the display edge with `.astimezone(ZoneInfo("Europe/Berlin"))`.
- Naive datetimes are acceptable only for genuinely zone-free concepts (a recurring "9:00 AM" alarm, a date of birth) — leave a comment when you use one deliberately.
- Never mix: comparing or subtracting naive and aware datetimes raises `TypeError`. If you hit that error, fix the naive side; don't strip tzinfo from the aware side.

**Red flags that you're about to violate this:**

- "`datetime.now()` is the standard way to get the current time."
- "`utcnow()` is the safe version, that's what the name says."
- "The server runs in UTC anyway, so naive is effectively aware."
- "I'll strip tzinfo so the comparison stops raising TypeError."
- "Timezone handling is out of scope for this small helper."

### Python Bind Loop Vars in Closures

NEVER create a closure (lambda or nested `def`) inside a Python loop that references the loop variable directly. Python closures capture by reference and resolve at call time, so every closure sees the loop's final value.

- Wrong: `callbacks = [lambda: handle(item) for item in items]` — all callbacks handle the last item.
- Right: bind at definition time with a default argument: `callbacks = [lambda item=item: handle(item) for item in items]`.
- Also right: `functools.partial(handle, item)` — clearer intent than the default-arg trick.
- Also right: extract a factory: `def make_handler(item): return lambda: handle(item)` — the function call creates a new scope per iteration.
- This applies to any late-executed code created in a loop: thread targets, signal handlers, `dict` of dispatch functions, pytest parametrization helpers, GUI callbacks.
- The same trap exists when closing over any variable that is reassigned later, not just loop variables. If the closure runs later and the variable changes, bind it.
- If a closure in a loop intentionally reads the live variable, add a comment saying so; otherwise assume it's a bug.

**Red flags that you're about to violate this:**

- "A lambda right here is more concise than defining a helper."
- "Each iteration creates its own lambda, so each one has its own `item`."
- "This worked when I wrote the same thing in JavaScript with `let`."
- "The callbacks fire immediately anyway, so capture timing doesn't matter."
- "Adding `item=item` looks redundant, so I'll clean it up."

**Red-flag bonus:** if you find yourself *removing* an existing `lambda x=x:` because it "looks like a typo," stop — that's the fix, not the bug.

### Python Equality Not Is

Use `is` ONLY for singletons (`None`, `True`, `False`, module-level sentinel objects) and deliberate identity checks. Use `==` for every value comparison. In Python, `is` compares object identity; it agrees with `==` for small ints and interned strings only by interpreter accident, so `is`-based value checks pass in tests and fail on real data.

- Wrong: `if status is "active":`, `if code is 200:`, `if char is 'x':` — replace with `==`.
- Right: `if value is None:`, `if value is not None:` — never `== None`, which invokes `__eq__` and misbehaves on numpy arrays, pandas objects, and ORM columns.
- Right: `if result is _MISSING:` where `_MISSING = object()` is a sentinel — identity is the point.
- Don't "fix" `is None` to `== None` for stylistic consistency; `is None` is the canonical form.
- For booleans, prefer `if flag:` over `if flag is True:` unless you specifically need to exclude truthy non-bool values — and say so in a comment if you do.
- Treat any `is` whose right-hand side is a literal (string, number) as a bug, full stop.

**Red flags that you're about to violate this:**

- "`is` reads more naturally here than `==`."
- "I tested it and `x is 5` returned True, so it's fine."
- "Identity is faster than equality, and this is a hot loop."
- "The codebase uses `is` for None, so I'll use it for strings too for consistency."
- "These are both literals, so they're obviously the same object."

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

### Python No Mutable Default Args

NEVER use a mutable object (`[]`, `{}`, `set()`, class instances) or any call expression (`datetime.now()`, `uuid4()`) as a Python default argument value. Python evaluates defaults once at definition time, so the same object is shared across all calls.

- Wrong: `def add(item, items=[]):` — every call without `items` appends to one shared list.
- Right: `def add(item, items=None):` then `if items is None: items = []` as the first lines of the body.
- Wrong: `def log(msg, when=datetime.now()):` — the timestamp is frozen at import.
- Right: `def log(msg, when=None):` then `when = when or datetime.now()` (use the explicit `is None` check if falsy values like `0` are valid inputs).
- Immutable defaults are fine: `None`, numbers, strings, `True`/`False`, tuples of immutables, `frozenset()`.
- In dataclasses, use `field(default_factory=list)` — never `= []`.
- When you see an existing mutable default in code you are editing, flag it; do not copy the pattern into new functions.

**Red flags that you're about to violate this:**

- "A default empty list is the cleanest signature here."
- "The None-check boilerplate makes the function longer for no reason."
- "This function is only called once, so sharing the default can't matter."
- "I'll default the timestamp to now() so callers don't have to pass it."
- "Other functions in this file already do `items=[]`, so I'll stay consistent."

### Python Strip Is Not Remove Prefix

NEVER use `strip()`, `lstrip()`, or `rstrip()` with a multi-character argument to remove a prefix or suffix. The argument is a character *set*, not a substring: `"production".lstrip("prod")` returns `"uction"`, and `"door".rstrip("or")` returns `"d"`.

- Right: `s.removeprefix("https://")` and `s.removesuffix(".py")` (Python 3.9+). These remove the exact substring once, or return the string unchanged.
- Pre-3.9 fallback: `s[len(p):] if s.startswith(p) else s` — write the conditional; do not reach for strip.
- `strip()` with no argument (whitespace) is fine and idiomatic. Single-character arguments like `s.strip('"')` are fine. The danger zone is exactly: multi-character argument intended as a substring.
- For path manipulation, don't strip extensions with string methods at all — use `pathlib`: `Path(name).stem`, `Path(name).with_suffix("")`.
- When you see `lstrip("http://")`, `rstrip(".json")`, or similar in existing code, treat it as a latent bug worth flagging even if you weren't asked to touch it — it corrupts only the inputs whose adjacent characters happen to overlap the set.
- Self-check before emitting `strip(x)` where `len(x) > 1`: do I mean "these characters" or "this substring"? If substring, switch methods.

**Red flags that you're about to violate this:**

- "`lstrip('https://')` removes the URL scheme — the name says strip from the left."
- "I tried it on one example and got exactly the prefix removed."
- "`rstrip('.py')` is shorter than slicing with startswith."
- "removeprefix might not exist in their Python version, so strip is safer."
- "The characters in the prefix are unlikely to repeat at the boundary."

### Rust No Unwrap Outside Tests

NEVER use `.unwrap()` or `.expect()` on a `Result`/`Option` in production code paths to avoid handling the error. Unwrap converts recoverable failures into panics; in a server it kills the thread, in a library it crashes the caller.

- Propagate by default: return `Result` and use `?`. If the error types don't line up, that's what `From` impls, `map_err`, or an error crate (`thiserror` for libraries, `anyhow` for binaries) are for — not a reason to unwrap.
- Wrong: `let n: u32 = input.parse().unwrap()` on external input. Right: `let n: u32 = input.parse().map_err(|e| ...)?` or match and handle.
- `Option` with a sensible fallback: `unwrap_or`, `unwrap_or_else`, `unwrap_or_default`, or `ok_or(...)?` to convert to a `Result`.
- Genuine invariants — cases that are provably impossible — may use `.expect("why this cannot fail: ...")` with the invariant stated in the message. Bare `.unwrap()` carries no such proof and should be treated as a TODO that escaped.
- Acceptable unwrap zones: tests, examples, build scripts, one-off CLI prototypes explicitly labeled as such, and constants checked at startup (`Regex::new(KNOWN_PATTERN)` — though `LazyLock` + `expect` with a message is still better).
- Do not bypass the rule with equivalents: indexing (`map[&key]`, `slice[i]`) and `panic!`/`todo!`/`unimplemented!` on reachable paths are unwraps in disguise.
- Don't swing to the opposite failure: silently swallowing errors (`let _ = ...`, `.ok()` discarding a Result that matters) is worse than panicking. The goal is *handled*, not *quiet*.

**Red flags that you're about to violate this:**

- "I'll unwrap for now and add error handling later."
- "This can't fail in practice." (Then write `expect` with the proof, and check the proof.)
- "Adding a Result return type means changing five callers."
- "The examples in the crate docs all use unwrap."
- "It's just a parse of a value we control." (Config files and env vars are external input.)
- "A panic is fine, the orchestrator will restart it."

### Shell Pipelines Hide Failures

ALWAYS account for the fact that a pipeline's exit status is the last command's status only. In any script where failure matters (CI, cron, backups, deploys), a failing producer hidden behind a succeeding consumer is the default behavior, not an edge case.

- Set `set -o pipefail` (bash) near the top of scripts: the pipeline then fails if any stage fails. Combine as `set -euo pipefail`.
- Wrong: `pg_dump "$DB" | gzip > "$OUT"` with no pipefail — a truncated dump still exits 0 and looks like a backup. Right: pipefail on, and verify the artifact (size, restore test) for anything you'd need in a disaster.
- `cmd | tee log` in CI: without pipefail, the build status is tee's status. This single line is responsible for a remarkable number of green-but-broken pipelines.
- Need a specific stage's status under POSIX sh (no pipefail)? Use `${PIPESTATUS[n]}` in bash, or restructure: write to a temp file, check, then process.
- pipefail + early-exiting consumers (`head`, `grep -q`, anything that stops reading): the producer gets SIGPIPE and the pipeline reports 141. Handle deliberately — restructure to avoid the early exit, capture to a variable first, or isolate that pipeline and check its status explicitly. Do NOT respond by deleting pipefail from the whole script.
- `grep` exits 1 on no matches: in a pipeline under `pipefail` + `set -e`, "nothing matched" becomes "script aborted." If empty results are valid, write `grep pattern file || true` with a comment, or test with `if grep -q ...`.

**Red flags that you're about to violate this:**

- "The pipeline ran and produced output, so it worked."
- "tee exits 0, but the build status comes from make." (It doesn't.)
- "pipefail made the script flaky, I'll remove it." (Investigate the 141 instead.)
- "It's a one-liner, strict mode is for long scripts."
- "grep returning 1 on no matches won't matter here."

### Shell Quote Every Variable

ALWAYS double-quote every variable and command substitution in shell: `"$var"`, `"$(cmd)"`, `"$@"`, `"${arr[@]}"`. Unquoted expansions undergo word splitting and glob expansion, so any value containing spaces, tabs, newlines, or `* ? [` becomes multiple arguments or a wildcard match.

- Wrong: `rm -rf $TMPDIR/build` — with a space in `TMPDIR` this deletes two paths, neither of them the right one. Right: `rm -rf "${TMPDIR}/build"`.
- Wrong: `[ $x = "ok" ]` — errors or misbehaves when `x` is empty or multi-word. Right: `[ "$x" = "ok" ]`, or use `[[ ]]` in bash (still quote for habit and copy-paste safety).
- Pass arguments through with `"$@"` (each argument preserved), never bare `$@` or `"$*"` (which joins them into one).
- Loop over command output with arrays or `while IFS= read -r line`, not `for f in $(ls)` — that splits on every space in every filename and glob-expands the pieces.
- Quote inside `${}` defaults too: `"${name:-default}"`.
- The few legitimate unquoted uses (deliberate globbing like `for f in *.log`, or intentional splitting of a flags variable) must be commented as intentional; better, use arrays for flag lists: `args=(-v --color); cmd "${args[@]}"`.
- Arithmetic contexts `$(( ))` and assignments `x=$y` are safe unquoted, but quoting them is harmless — when in doubt, quote.

**Red flags that you're about to violate this:**

- "This variable is a path I control, it'll never have spaces."
- "Quoting everything makes the script noisy; I'll quote where it matters."
- "It's a quick CI script, not production code." (CI deletes directories for a living.)
- "The original script didn't quote it and it works."
- "`$@` and `\"$@\"` are basically the same thing."
- "I'm just cleaning up the quoting style." (Removing quotes is never cleanup.)

### Shell set -e Has Blind Spots

NEVER treat `set -e` as complete error handling in shell scripts. Errexit is silently suspended in several constructs; handle those failure paths explicitly.

- Start scripts with `set -euo pipefail` (bash), but treat it as a backstop, not the strategy.
- `local var=$(cmd)` discards cmd's exit status — `local` returns 0. Split it: `local var` on one line, `var=$(cmd)` on the next; now the assignment's status is cmd's status and errexit can see it. Same for `export` and `declare`.
- Inside `if cond`, `while cond`, `! cmd`, and the left side of `&&`/`||`, failures do not trigger errexit — by design. If a function is called in a condition, its whole body runs with errexit off; keep such functions trivial or check statuses manually inside them.
- `set -u`: expanding an unset variable is fatal — this catches typos and missing environment that `set -e` never would. Use `"${VAR:?message}"` to demand required variables with a useful error.
- After a command whose failure needs cleanup or a specific message, check explicitly: `if ! cmd; then echo "..." >&2; exit 1; fi`. Explicit beats implicit for anything destructive.
- `cmd || true` disables checking for that command — only write it when failure is genuinely acceptable, with a comment saying why.
- Don't rely on errexit semantics being portable: `sh`/dash/old bash differ. Explicit checks are portable.

**Red flags that you're about to violate this:**

- "The script has `set -e`, so any failure stops it."
- "`local output=$(build)` — if build fails, we exit." (You don't.)
- "I'll wrap this in a function and call it from the if-condition." (Errexit is now off inside it.)
- "Adding explicit error checks is redundant with strict mode."
- "`|| true` here just keeps the script tidy."

### Shell Test Numbers vs Strings

ALWAYS match the comparison operator to the data type in shell tests: `=`/`!=` for strings, `-eq`/`-ne`/`-lt`/`-le`/`-gt`/`-ge` for integers. They are not interchangeable and the failure modes differ — wrong-typed integer ops error at runtime; wrong-typed string ops silently mis-compare values like `" 0"` vs `"0"`.

- Numeric tests: `[ "$count" -eq 0 ]`, or better in bash, arithmetic context: `(( count == 0 ))`, which is built for numbers and supports `<`, `>=` naturally.
- String tests: `[ "$mode" = "prod" ]`. Use single `=` in `[ ]` for portability; `==` is a bashism that breaks under `sh`.
- NEVER use `<` or `>` inside `[ ]` — they are parsed as redirections: `[ "$a" > "$b" ]` always succeeds and creates a file. Inside `[[ ]]` they compare *lexicographically*: `[[ 9 < 10 ]]` is false. For numeric order use `-lt`/`-gt` or `(( ))`.
- Sanitize before numeric comparison: command output like `wc -l` can carry whitespace. Strip it (`count=$(wc -l < file)`, or `count=${count//[[:space:]]/}`) or the integer ops will error on `" 42"` under some shells.
- Validate that a variable is actually numeric before `-eq` if it comes from user input or environment: `[[ "$n" =~ ^[0-9]+$ ]]`.
- Know your bracket: `[ ]` is POSIX and word-splits (quote everything); `[[ ]]` is bash/ksh/zsh-only, safer parsing, supports `=~`. Pick per script shebang and stay consistent.
- Empty/unset checks are string ops: `[ -z "$var" ]` / `[ -n "$var" ]`, always quoted.

**Red flags that you're about to violate this:**

- "`==` works for comparing anything."
- "I'll use `>` to compare the version numbers." (Lexicographic: `9 > 10`.)
- "These are numbers, but `=` compares them fine." (Until the formatting differs.)
- "The test errored, but the else-branch handled it." (The else-branch ran *because* it errored.)
- "`[` and `[[` are the same thing with different spelling."

### SQL Implicit Casts Kill Indexes

ALWAYS match the literal/parameter type to the column type in SQL predicates and joins. A type mismatch makes the database cast — often casting the *column*, which disables its index and can change matching semantics, all without any error.

- Check the schema before writing the predicate. VARCHAR column means quoted string: `WHERE phone = '5551234567'`, never `WHERE phone = 5551234567` (numeric literal forces a per-row cast of the column in MySQL: full scan, plus `'...abc'` suffixed strings matching).
- Numeric column means numeric parameter: passing `'42'` as a string usually casts the parameter (harmless), but dialect rules vary — don't rely on getting the lucky direction. Bind parameters with the correct type in application code rather than leaning on coercion.
- Never wrap an indexed column in a function or cast in WHERE/JOIN: `WHERE DATE(created_at) = ?`, `UPPER(email) = ?`, `CAST(id AS CHAR) = ?` all disqualify the plain index. Restructure to range predicates (`created_at >= '2026-06-01' AND created_at < '2026-06-02'`), store/compare normalized values, or create the matching functional index deliberately.
- Joins across tables: joining a VARCHAR key to an INT key (or mismatched collations/charsets in MySQL) silently de-indexes the join. Fix the schema or cast the side that isn't indexed for the lookup.
- Verify with the planner, not vibes: `EXPLAIN` the query and look for full scans and cast/collation notes on what should be an index lookup.
- When a query is mysteriously slow but correct, type mismatch is one of the first three suspects. Check it before adding an index that already exists.

**Red flags that you're about to violate this:**

- "The value is numeric, so I'll write it without quotes."
- "The database will cast it; same result either way."
- "The query returns the right rows, it's correct."
- "It's fast in my testing." (On the 200-row dev table.)
- "I'll just wrap the column in DATE() to compare days, it reads cleanly."
- "The ORM handles parameter types for me." (Until a raw fragment or a string-typed variable sneaks in.)

### SQL NULL Needs IS, Not Equals

NEVER compare against NULL with `=` or `<>` in SQL — any comparison with NULL is UNKNOWN, and UNKNOWN rows are excluded by WHERE. Use `IS NULL` / `IS NOT NULL`.

- Wrong: `WHERE deleted_at = NULL` — matches zero rows unconditionally. Right: `WHERE deleted_at IS NULL`.
- Inequality filters exclude NULL rows: `WHERE status <> 'archived'` drops rows with NULL status. If NULLs should be included, say so: `WHERE status <> 'archived' OR status IS NULL`, or use `IS DISTINCT FROM 'archived'` where the dialect supports it.
- NEVER use `NOT IN` with a subquery whose column can be NULL — one NULL makes the entire predicate UNKNOWN and returns zero rows. Use `NOT EXISTS` (NULL-safe and usually better-planned) or filter NULLs in the subquery explicitly.
- NULL-safe equality where you genuinely mean "same, treating NULL as a value": standard `IS NOT DISTINCT FROM`, MySQL `<=>`. Don't emulate it with `COALESCE(col, 'sentinel')` unless the sentinel provably can't collide.
- Remember the aggregate asymmetry: `COUNT(*)` counts rows; `COUNT(col)` counts non-NULL values; `AVG(col)` divides by the non-NULL count. Pick deliberately.
- `NULL || 'text'` and arithmetic with NULL yield NULL — string-building and computed columns propagate absence; wrap with `COALESCE` when output must be non-NULL.
- In ORMs and query builders, check what `.where(field: nil)` style filters actually emit — most translate correctly, but raw-fragment escapes (`where("status <> ?")`) reintroduce the trap verbatim.

**Red flags that you're about to violate this:**

- "`= NULL` is the SQL spelling of `== null`."
- "`<> 'archived'` means everything that isn't archived." (NULL isn't 'not archived'; it's unknown.)
- "`NOT IN (subquery)` is the natural way to write this exclusion."
- "The query runs without errors, so the logic is right."
- "COUNT is COUNT; the column argument is cosmetic."

### YAML Quote Ambiguous Scalars

ALWAYS quote YAML values that are strings but look like another type. YAML type-guesses unquoted scalars, and several legitimate strings parse as booleans, numbers, or null with no warning.

- Quote anything matching these shapes when a string is intended: `yes/no/on/off/y/n/true/false` in any case (`country: "NO"`), version-like numbers (`version: "1.10"` — unquoted it's the float `1.1`), leading-zero values (`mode: "0755"`, zip codes like `"02134"`), scientific-notation lookalikes (`"1e5"`), colon-separated times (`"12:30"`), and `null`/`~`.
- All-digit identifiers (phone numbers, account ids, some Git SHAs) must be quoted or they become integers — possibly losing leading zeros or precision.
- An empty value (`key:`) is `null`, not `""`. Write `key: ""` for empty string.
- Booleans and numbers that are MEANT to be booleans and numbers stay unquoted: `enabled: true`, `replicas: 3`. The rule is about strings in disguise.
- Never strip quotes from existing YAML as cleanup. A quote in a config file is load-bearing until proven decorative.
- When generating YAML programmatically, use a real YAML library, not string templating — templating an unquoted user-supplied value into YAML is both a coercion bug and an injection bug.
- Be alert in the usual blast zones: docker-compose/CI image tags (`image: postgres:9.6` is fine; `tag: 9.60` is the float trap), Kubernetes env vars (all values must be strings — unquoted `PORT: 8080` fails or coerces depending on tooling), Ansible/Helm values files, and country/language code lists.

**Red flags that you're about to violate this:**

- "Quotes around simple values are unnecessary noise in YAML."
- "I'll normalize this config by removing redundant quoting."
- "It's a version number, YAML will keep it as written."
- "The parser we use is YAML 1.2, the boolean thing is fixed." (Is every consumer of this file?)
- "Env var values are obviously strings, no need to quote 8080."
