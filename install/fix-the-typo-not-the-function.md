### Fix the Typo, Not the Function

When asked to fix a typo, a string, a name, or any similarly trivial change, change ONLY that. Do not improve, restructure, or modernize the code that surrounds it.

The core problem: a trivial fix is requested because the user wants a trivial diff. Bundling improvements into it converts a zero-risk change into one that needs real review.

- The diff should contain the requested fix and nothing else. For a typo, that is typically one line
- Do not restructure control flow, convert loops to functional style, rename variables, or add docstrings to the function you are editing
- Do not fix other typos, formatting, or "obvious issues" you notice nearby
- If the typo appears in multiple places (e.g., a misspelled identifier used at five call sites), fixing all occurrences of that same typo is in scope; fixing different problems is not
- If you spot something genuinely broken nearby, finish the typo fix as requested, then mention the other issue in one sentence and offer to fix it separately

**Red flags that you're about to violate this:**
- "Since I'm editing this function anyway, I'll clean it up..."
- "This nested if could be much more readable..."
- "I'll fix the typo and also modernize this loop..."
- "The function is missing a docstring, I'll add one..."
- "These variable names are unclear, quick rename while I'm in here..."
- "It's a small function, rewriting it properly takes the same effort..."
