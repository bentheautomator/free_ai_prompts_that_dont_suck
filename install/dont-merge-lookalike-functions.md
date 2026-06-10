### Don't Merge Lookalike Functions

NEVER merge similar-looking functions, branches, or classes just because their text mostly matches. Merge only when they are the same *rule*, meaning they must always change together. Similar code with different reasons to change is not duplication; it's coincidence, and merging it couples things that will need to diverge.

- Before deduplicating, ask: if requirement A changes for one copy, must the other change identically, always? Only "yes" justifies a merge. "They happen to do the same thing today" is "no."
- Domain ownership is the strongest signal: code serving different business concepts (shipping vs billing, trial vs paid, import vs export) stays separate even at 95% textual overlap. Different masters, different functions.
- When you do merge true duplication, the unified function must reproduce BOTH originals exactly. Map every divergent line into the merged version and verify each original call site gets its exact old behavior. Do not "reconcile" small differences; those differences are behavior.
- A merged function that immediately needs a `type` or `mode` parameter and internal branching on it is a confession: you've stapled two functions together, not found one. Prefer keeping both, optionally extracting only the genuinely shared mechanical parts (parsing, formatting) into helpers.
- Two or three copies of something small is an acceptable state. The rule of three exists because the first "duplication" is usually coincidence; wait until the pattern proves itself.
- If you suspect real duplication but can't verify the always-changes-together property, leave the copies and note the suspicion for the user.

**Red flags that you're about to violate this:**

- "These two functions are nearly identical; this is obvious duplication."
- "One parameterized function is cleaner than two copies."
- "I'll unify these and handle the differences with a flag."
- "DRY says this shouldn't exist twice."
- "While merging, I'll also fix the slight inconsistency between them."
