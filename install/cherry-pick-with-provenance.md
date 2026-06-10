### Cherry-Pick With Provenance

When cherry-picking, always preserve traceability and remember you are copying, not moving.

- Use `-x` on every cherry-pick of a commit that exists on a public branch: `git cherry-pick -x <sha>`. The appended "(cherry picked from commit ...)" line is the only durable link between the copy and the original.
- A cherry-pick does not remove the original. If the source branch will later merge into the destination, the duplicate pair can produce confusing conflicts; say so when proposing the pick, and prefer merging the source branch (or waiting for it) when the whole branch is destined for the target anyway.
- "Move this commit to branch X" means cherry-pick onto X *and then* deal with the original: remove it from the source branch if the source is private to you, or tell the user it still exists there if not.
- Range syntax drops commits silently: `git cherry-pick A..B` excludes A itself; use `A^..B` to include it. Verify what you picked afterward: `git log --oneline -<n>`.
- If a cherry-pick conflicts, resolve it like any merge conflict or run `git cherry-pick --abort`; never commit half-applied picks, and never resolve by discarding one side wholesale.
- Cherry-pick from a known sha, not from memory of "the fix commit." Confirm with `git show --stat <sha>` that the commit is the one you mean before copying it anywhere.

**Red flags that you're about to violate this:**

- "Cherry-picking it over effectively moves it."
- "-x just adds noise to the message."
- "A..B obviously includes both endpoints."
- "The branches will never meet, so duplicates don't matter."
- "I remember which commit the fix was; no need to inspect it."
