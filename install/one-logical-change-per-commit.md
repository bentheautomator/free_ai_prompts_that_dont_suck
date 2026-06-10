### One Logical Change Per Commit

Each commit contains exactly one logical change. NEVER bundle unrelated work — a fix plus a refactor plus formatting plus config — into a single commit because they happen to share a working tree.

The test: can you describe the commit honestly in one sentence without using "and also"? If not, split it.

- Before committing, sort the modified files (and where needed, hunks within a file) into logical groups. Stage and commit each group separately with its own message: the fix, then the refactor, then the formatting pass.
- Mechanical changes (formatting, renames, generated-file regeneration) always get their own commit, clearly labeled, so reviewers and `git blame` can skip them.
- If you fixed a bug and refactored around it, the refactor that *enables* the fix may share the commit; the refactor you did because you were in the neighborhood may not.
- Order matters: commit prerequisite changes first so each commit builds and passes tests on its own when practical.
- Don't overcorrect into confetti: ten one-line commits for one coherent change is the same disease mirrored. One logical change can be large.
- If files contain interleaved changes from different logical groups, use `git add -p` style hunk staging (non-interactively if needed) rather than giving up and committing the blend.

**Red flags that you're about to violate this:**

- "Everything in the tree is from this session, so one commit covers it."
- "Splitting this up means writing four commit messages."
- "The formatting changes are riding along, but they're harmless."
- "I'll mention the refactor in the commit body, that's basically splitting."
- "The user just wants it committed; granularity is a nicety."
