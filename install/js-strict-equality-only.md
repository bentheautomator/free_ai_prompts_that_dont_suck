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
