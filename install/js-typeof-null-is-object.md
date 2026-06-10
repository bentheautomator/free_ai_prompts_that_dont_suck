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
