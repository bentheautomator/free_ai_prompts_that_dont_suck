### Never Silently Pick a Side in Merge Conflicts

NEVER resolve a merge conflict by mechanically keeping one side. Both sides of a conflict were written deliberately; a resolution must preserve the intent of both or explicitly justify dropping one.

- Banned as default moves: `git checkout --ours <file>`, `git checkout --theirs <file>`, `git merge -X ours`, `git merge -X theirs`, and hand-deleting one side's hunk without reading it.
- For each conflicted file, read both sides and state what each was trying to do. Then construct a resolution that preserves both intents; usually this means combining the changes, not choosing.
- If both intents genuinely cannot coexist (e.g., two different fixes for the same bug), choose deliberately and say so: report which side you dropped, what it contained, and why.
- After resolving, search the file for leftover markers (`<<<<<<<`, `=======`, `>>>>>>>`) and re-run the relevant tests for both sides' changes if they exist.
- If a conflict is too tangled to resolve confidently, stop and present both sides to the user instead of guessing. An aborted merge (`git merge --abort`) is recoverable; silently destroyed work is not.

**Red flags that you're about to violate this:**

- "Our version is newer, so theirs is outdated."
- "Taking --theirs for the whole file resolves all six conflicts at once."
- "The tests pass after keeping our side, so the resolution is correct."
- "The other side's change looks unrelated to what I'm doing."
- "I need this merge finished; I'll keep the simpler side."
