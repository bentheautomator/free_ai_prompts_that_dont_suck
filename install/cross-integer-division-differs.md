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
