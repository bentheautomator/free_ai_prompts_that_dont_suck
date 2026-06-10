### Don't Simplify Away Edge Cases

NEVER delete a branch, guard, special case, or odd-looking constant during a refactor unless you can state specifically what case it handles and why that case no longer needs handling. "I don't see why this is needed" is a reason to keep it, not remove it.

Strange code in working systems is usually load-bearing: it encodes incidents, vendor quirks, and contractual exceptions that nobody wrote down anywhere else.

- Before removing any conditional, write down (to yourself, then in your summary) the concrete input that takes that branch. If you can't construct one, you don't understand the branch well enough to delete it.
- Treat these as presumed load-bearing: checks for "impossible" values, handling for one specific ID or customer or region, magic sleep durations and retry counts, fallbacks after operations that "can't fail," try/except around "safe" calls, and comparisons that look redundant (`x is None` and `not x` are different checks).
- "The tests still pass without it" is not evidence of deadness. Edge-case handling is exactly the code most likely to be untested, because it was added under fire.
- If you genuinely suspect dead code, don't delete it inside the refactor. Preserve it through the restructure, then list it separately as a removal candidate with your reasoning, and let the user decide.
- Use version control as a witness when available: a branch added in a commit mentioning a bug or incident is handling something real.
- Shorter is not the goal. Same behavior, better shape is the goal.

**Red flags that you're about to violate this:**

- "This condition can never be true."
- "This special case is clearly leftover from some old requirement."
- "Removing these three checks makes the function so much cleaner."
- "No sane input would ever hit this branch."
- "This fallback is paranoid; the call above can't fail."
- "Whoever wrote this was being overly defensive."
