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
