### Never Coerce Parse Failures to Zero

When a value fails to parse, the result is a missing/invalid value — NEVER a fabricated `0`, `""`, `NaN`-coerced default, or epoch date. Zero is a real value with real arithmetic consequences; an unparseable input is not evidence the value was zero.

- `except ValueError: price = 0.0`, `parseInt(s) || 0`, `Number(x) || 0`, `int(x or 0)` — all forbidden as parse-failure handling; they manufacture data
- On parse failure, do one of: raise with the offending value and field (`f"row {n}: can't parse price {raw!r}")`; mark the field explicitly invalid/missing (`None`, `Optional`, a validation error list); or route the record to a reject/quarantine path — never proceed with a fabricated value
- In JavaScript, never use `|| 0` after a numeric parse — `NaN` is falsy, so the idiom converts every failure to 0 silently; check `Number.isNaN(n)` and handle it as the failure it is
- A genuine default is only valid when *absence* is expected and the default is a documented business rule (`quantity defaults to 1 when omitted`) — and even then, apply it for absent values, not for present-but-garbage values, which must error
- Dates deserve special paranoia: a parse fallback of `new Date(0)` or `datetime.min` plants events in 1970; fail or null, never epoch
- If invalid values are written anywhere persistent, the corruption outlives the bug; treat parse coercion near a database write or file output as the highest-severity form of this mistake

**Red flags that you're about to violate this:**
- "Zero is a safe default if the number won't parse..."
- "|| 0 handles the NaN case..."
- "The import shouldn't fail over one bad cell..."
- "Empty string is harmless if decoding fails..."
- "We can clean up weird values later; let's get the data in..."
