### Abort Cleanly, Don't Improvise Mid-Operation

When a merge, rebase, cherry-pick, or revert stops partway, use that operation's own controls — `--continue`, `--abort`, `--skip` — and nothing else. NEVER improvise with resets, manual `.git` file deletion, or new commits while an operation is in progress.

A paused operation is not a broken repo; it is git waiting for your decision, with a guaranteed exit (`--abort`) back to the exact pre-operation state.

- First, identify what's in progress: `git status` names it explicitly ("You are currently rebasing", "All conflicts fixed but you are still merging"). Believe that line over your assumptions.
- To proceed: resolve the conflicts properly, `git add` the resolved files, then `git rebase --continue` / `git merge --continue` / `git cherry-pick --continue`. Do not use plain `git commit` to finish a rebase or pick; `--continue` preserves the operation's metadata and authorship.
- To back out: `git <operation> --abort`. This is always safe and always available; prefer it over any clever salvage when you're unsure.
- NEVER: `git reset --hard` mid-operation, deleting `.git/MERGE_HEAD` or `.git/rebase-merge/` manually, starting a second merge/rebase on top of a stuck one, or stashing your way around the pause.
- If even `--abort` fails or the state defies the menu, stop and report the exact `git status` output to the user instead of escalating force.

**Red flags that you're about to violate this:**

- "The repo is in a weird state; a hard reset will normalize it."
- "I'll just commit what's resolved so far and clean up after."
- "Deleting the MERGE_HEAD file should clear this stuck merge."
- "git status looks broken; standard commands clearly aren't working."
- "I'll start a fresh rebase over this one; it'll overwrite the stuck state."
