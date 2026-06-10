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
