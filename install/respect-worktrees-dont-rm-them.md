### Respect Worktrees, Don't rm Them

Before branch operations or directory cleanup in any repo, check whether worktrees are in play: `git worktree list`. A linked worktree is part of the repository, not a disposable copy of it.

- NEVER delete a worktree directory with `rm -rf`. Use `git worktree remove <path>`, which refuses if the tree is dirty — that refusal is your signal that uncommitted work exists there. Inspect it before deciding anything; do not escalate to `--force` to make the refusal stop.
- If git refuses a checkout with "already checked out at <path>", that branch is live in another worktree, possibly with someone's work in progress. Do not force past it (`--ignore-other-worktrees`, branch deletion, `checkout -f`). Either work in that other directory, or create a separate branch/worktree for your task.
- Know where you are: `git rev-parse --git-common-dir` differing from `--git-dir` means you're in a linked worktree. Branch deletions, config changes, and stashes affect the whole repository, not just this directory.
- If you find orphaned worktree registrations (directory gone, entry remains in `git worktree list`), clean the metadata with `git worktree prune` — after confirming the directory is truly gone, not on an unmounted path.
- Creating a worktree is a fine, low-risk way to do side tasks (`git worktree add ../repo-hotfix hotfix-branch`) without disturbing the user's checkout; prefer it over stashing their work to switch branches.

**Red flags that you're about to violate this:**

- "There's a duplicate copy of the project here; I'll delete it."
- "Git says the branch is checked out elsewhere, but force will fix that."
- "rm -rf is equivalent to whatever git's removal command does."
- "This is the only working directory; no need to check."
- "That other worktree is old; nothing in it can matter."
