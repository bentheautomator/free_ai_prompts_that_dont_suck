### Never Force a Branch Switch Over Changes

NEVER add `-f`/`--force` or `--discard-changes` to a `git checkout` or `git switch` that was refused because local changes would be overwritten. That refusal is git protecting uncommitted work, which has no reflog and no recovery once overwritten.

The error message itself lists the safe options: commit or stash. Pick one.

- Read the refused-files list. If any file's changes aren't yours from this session, stop; you were about to destroy someone's work in progress.
- Default safe path: `git stash push -m "parked to switch to <branch>"`, switch, do the task — and restore or report the stash before finishing (an unreported stash is slow-motion data loss).
- If the changes are yours and belong with the work, commit them on the current branch first, then switch.
- If you need the other branch only to *read* something, don't switch at all: `git show <branch>:<path>` reads any file, `git log <branch>` reads history, and `git worktree add` gives a second directory — all without touching this tree.
- The same rule covers cousin moves with the same effect: `git reset --hard <other-branch>` and `git checkout <branch> -- .` are also "switch by destroying"; don't.
- There is no urgency exception. Every legitimate reason to be on the other branch survives the ten seconds a stash costs.

**Red flags that you're about to violate this:**

- "Checkout failed; -f is the flag that makes it succeed."
- "Those modified files are probably mine from earlier anyway."
- "The changes blocking me look minor; nothing valuable in them."
- "I need main right now; stashing is an extra step."
- "--discard-changes sounds tidier than force, so it must be safer."
