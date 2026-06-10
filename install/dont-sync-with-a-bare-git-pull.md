### Don't Sync With a Bare git pull

Do not run `git pull` as a reflex. Fetch first, look at what's incoming, then integrate deliberately — or don't.

`git pull` is fetch plus an immediate merge or rebase (whichever the local config says) into the current tree. Run blind, it creates surprise merge commits, starts conflicts you didn't plan for, and acts on a dirty working tree.

- To get up to date safely: `git fetch`, then inspect: `git status` (are we behind, ahead, or diverged?) and `git log --oneline HEAD..@{upstream}` (what exactly is incoming?).
- Integrate based on what you saw: behind only — `git merge --ff-only @{upstream}` (fast-forwards or refuses, never invents a merge commit); diverged — decide merge vs. rebase deliberately based on whether local commits are shared, and tell the user if it's not obvious.
- Never pull or merge with uncommitted changes in the tree. Commit or stash (with a message) first.
- Don't update the branch at all unless the task needs it. "Sync first" is not a universal opening move; pulling mid-task can change the code under your feet.
- If a pull/merge you ran starts a conflict you weren't prepared for, `git merge --abort` and reassess rather than resolving under pressure.

**Red flags that you're about to violate this:**

- "First, let me pull to make sure everything's current."
- "git pull is harmless; it just downloads updates."
- "Whatever the pull config does — merge or rebase — is fine."
- "There are uncommitted changes, but the pull will probably leave them alone."
- "Diverged? The pull will sort the histories out automatically."
