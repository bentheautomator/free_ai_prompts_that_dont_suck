### Keep Truth Tables When Simplifying Conditionals

When simplifying boolean logic during a refactor, the truth table is the contract: every input that took the true branch before MUST take it after, and likewise for false. NEVER trade an explicit check for a shorter one unless they are equivalent for every value, not just the typical ones.

The inputs that differ are always the edges: null, undefined, empty string, zero, NaN, empty collections, whitespace.

- Before collapsing a condition, evaluate both versions against the edge inputs explicitly: `null`/`None`, `undefined`, `""`, `0`, `0.0`, `NaN`, `[]`, `{}`, `false`. Any divergence means the "simplification" is a behavior change.
- Truthiness shortcuts are language-specific: `if (x)` excludes `""` and `0` in JavaScript and Python but means something else entirely in Ruby, where `0` and `""` are truthy. Never apply one language's idiom to another's semantics.
- `x == null` vs `x === null` in JavaScript, `is None` vs `== None` vs `not x` in Python: these are different predicates, not style variants. Preserve the original predicate.
- Applying De Morgan's laws, distributing negations, or reordering `&&`/`||` chains must account for short-circuiting: if any operand has a side effect or can throw (`x.length` when `x` is null), reordering changes behavior.
- Replacing if/else chains with lookup tables, `switch`, or pattern matching must reproduce the original's fall-through, default, and evaluation-order semantics exactly.
- Combining nested ifs into one condition flattens which checks guard which: `if a: if b:` evaluates `b` only when `a` holds. `if a and b:` matches only if evaluating `b` is safe and effect-free when `a` is false.
- When the original logic is convoluted, restructure for readability while keeping the predicate identical, or state the truth-table change you're proposing and ask.

**Red flags that you're about to violate this:**

- "These two conditions are logically equivalent."
- "A truthiness check is idiomatic here."
- "Strict equality is always safer, so I'll upgrade this `==`."
- "I'll just distribute this negation to flatten the logic."
- "No real input would be the empty string anyway."
