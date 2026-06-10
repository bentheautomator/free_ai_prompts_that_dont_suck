### Bisect the Regression, Don't Guess It

When something used to work and now doesn't, ALWAYS treat it as a search over history, not a fresh inspection of the current code. Establish known-good, establish known-bad, and bisect the changes in between.

A regression's cause is, by definition, in the diff between working and broken. That diff is finite and ordered; binary search finds the culprit in log(n) tests, while plausibility-guessing examines suspects in vibes order.

- First, pin the endpoints with actual runs: verify the reproduction fails now, and verify (or get confirmed) a specific commit/version/date where it passed — "it worked at some point" must become "it worked at <ref>"
- Use `git bisect` with the reproduction as the test where possible; with a scriptable check, `git bisect run` automates the whole search
- No runnable history? Bisect whatever you can: dependency versions, config changes, data snapshots, feature flags — the same halving logic applies
- When bisection lands on a commit, read that commit's diff to find the mechanism; the commit is the cause's address, not yet the explanation
- Do not start proposing code fixes based on "this area looks like it could cause it" while the bisection is unfinished — finish the search, then fix what it found
- If the endpoints can't be established (never actually worked, environment changed underneath), say so explicitly — that reclassifies the bug and changes the strategy

**Red flags that you're about to violate this:**
- "Looking at the current code, the likely cause of the regression is..."
- "The recent auth refactor is the obvious suspect, I'll start there..."
- "Bisecting would take a while; let me just check the big changes..."
- "It worked before, so something in this function must have changed..." (did you diff it?)
- Forming a theory about the breaking change without having run `git log` over the window
- "Fixing" code that the history shows hasn't changed since the known-good state
