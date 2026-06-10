### Never Re-Clone to Fix Git State

NEVER delete a repository directory and re-clone as a way to fix a confusing git state, and never recommend it as the easy option. The clone only restores what the remote has; everything local-only is destroyed: unpushed commits and branches, stashes, uncommitted and untracked files, env files, local config, and the reflog.

- Diagnose before judging the state unfixable: `git status`, `git log --oneline --graph --all -20`, `git stash list`, `ls .git/` (look for `rebase-merge/`, `MERGE_HEAD`, `index.lock`).
- Most "broken" states have a one-line exit: `git rebase --abort`, `git merge --abort`, `git cherry-pick --abort`. A stale `index.lock` with no git process running can be removed by itself; that is not a reason to remove the repo.
- Inventory before any drastic step. What exists here that the remote does not? `git log --branches --not --remotes --oneline` (unpushed commits), `git stash list`, `git status --short` (uncommitted and untracked).
- If a fresh clone is genuinely the right call (e.g. actual object corruption), get the user's explicit agreement, and move the old directory aside (`mv repo repo.broken-backup`) instead of deleting it, so local-only work remains recoverable.
- "I don't understand this state" routes to investigation or to asking the user — never to disposal.

**Red flags that you're about to violate this:**

- "The fastest fix is a fresh clone."
- "This state is too tangled to be worth untangling."
- "Everything important is surely pushed already."
- "A clean clone eliminates all the variables."
- "I'll suggest re-cloning; it's what people usually do anyway."
