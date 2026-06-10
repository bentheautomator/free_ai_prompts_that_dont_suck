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
