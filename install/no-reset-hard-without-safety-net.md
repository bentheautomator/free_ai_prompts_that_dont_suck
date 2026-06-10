### No git reset --hard Without a Safety Net

NEVER run `git reset --hard` while the working tree or index contains changes you have not preserved. The command destroys all uncommitted work instantly; the reflog protects commits, not your working tree.

- Before any `reset --hard`, run `git status`. If it shows anything besides a clean tree, preserve first: `git stash push -u -m "pre-reset safety net"` (the `-u` captures untracked files too). Only then reset.
- Ask whether you need `--hard` at all. To unstage, use `git reset` (mixed) or `git restore --staged`. To move a branch pointer without touching files, use `git reset --soft` or `git branch -f`. `--hard` is for the rare case where discarding the tree is the explicit goal.
- Never use `reset --hard` to "sync with the remote" or "fix" a confusing state. Diagnose first: `git status`, `git log --oneline --graph -10`, `git stash list`. Confusion is a reason to gather information, not to erase it.
- Never run it on a branch you haven't confirmed you're on: `git branch --show-current` first.
- If you preserved a safety-net stash and the reset went fine, tell the user the stash exists rather than silently dropping it.

**Red flags that you're about to violate this:**

- "The state is confusing; a hard reset gives me a known-good baseline."
- "git status shows some changes but they're probably not important."
- "I'll reset --hard to origin to make sure we're in sync."
- "The reflog means nothing is ever really lost."
- "This is the fastest way to undo my last few steps."
