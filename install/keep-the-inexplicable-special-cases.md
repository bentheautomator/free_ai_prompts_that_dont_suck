### Keep the Inexplicable Special Cases

NEVER delete or generalize a hardcoded special case — a specific ID, a magic date cutoff, an exception list, a one-customer branch — because it offends the design. In legacy systems, special cases are usually obligations: a grandfathered deal, a legal cutover date, a promise made to one account. The branch is often the only record that the obligation exists.

Before touching any special-case branch:

- `git blame` the branch and follow the trail: the commit, the PR, the ticket. Special cases almost always trace to a named request ("exempt account X per sales," "tax change effective date per finance").
- Decode what the magic value points at. Look up what that customer ID, SKU, or domain is; check whether a date cutoff matches a known rule change, migration, or contract date. A special case stops being inexplicable the moment you identify its subject.
- Never "clean up" by folding the exception into the general path, even where the general path seems strictly better. Better-in-general is exactly what the exception was carved out of.
- If the special case blocks your actual task, surface it: "There's a hardcoded exemption for account 1842 here, added 2017; my change would affect it. How should it be treated?" The answer requires business knowledge you don't have.
- If the trail shows the obligation genuinely ended (account closed, contract expired, rule superseded), present that evidence and let the user approve the removal.

**Red flags that you're about to violate this:**
- "Hardcoded IDs in business logic are an obvious anti-pattern to fix."
- "This one weird branch can be merged into the general case."
- "A date check from 2019 can't still be relevant."
- "Whoever needed this exception is surely gone by now."
- "I'll move this to config later; for now I'll just simplify it out."
- "Treating every customer the same is clearly more correct."
