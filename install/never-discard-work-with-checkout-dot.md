### Never Discard Work With git checkout .

NEVER run `git checkout .`, `git checkout -- <path>`, `git restore .`, or `git restore <path>` to discard changes. These commands permanently destroy uncommitted work; there is no reflog, stash, or undo for what they delete.

The working tree may contain the user's uncommitted changes mixed with yours. A wildcard discard cannot tell them apart.

- To undo your own changes, prefer reversible moves: re-edit the file back, or `git stash push -m "discarding: <reason>" <paths>` so the content survives and can be recovered.
- If you must discard, discard only specific files you personally modified in this session, name them to the user first, and confirm via `git diff <file>` that nothing in the diff is unfamiliar.
- If `git status` or `git diff` shows changes you did not make, do not discard anything; report what you found and let the user decide.
- Never combine discards with other cleanup (`git clean`, `git reset --hard`) in one step; each destructive command needs its own justification.
- "Get back to a clean state" is not a goal that justifies deleting work. A dirty working tree is a normal condition, not an error.

**Red flags that you're about to violate this:**

- "My approach failed, I'll reset everything and start fresh."
- "The working tree is messy; let me clean it up first."
- "These modifications are probably all mine from earlier."
- "git checkout . is the standard way to undo local changes."
- "The user wants the bug fixed, not these half-finished edits."
