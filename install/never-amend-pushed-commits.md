### Never Amend Pushed Commits

NEVER run `git commit --amend` on a commit that has been pushed to a remote. Amending rewrites the commit; if the original is already on the remote, you have forked history and the only way forward is a force-push that breaks everyone who pulled it.

- Before any `--amend`, verify the commit is local-only: `git log --oneline @{upstream}..HEAD` must include HEAD. If there is no upstream, check `git branch -r --contains HEAD`; if any remote branch contains it, do not amend.
- If the commit is already pushed, make a new commit instead. A small `fix: correct typo in previous change` commit is correct; rewritten shared history is not.
- This applies to all forms: `--amend`, `--amend --no-edit`, and amend-equivalents like `git rebase` onto a parent of a pushed commit.
- The sole exception is when the user explicitly confirms the branch is theirs alone and asks for the rewrite, after you state that a force-push will be required.
- Never chain amend with push: if you find yourself planning `--amend` followed by `push --force`, stop and report instead.

**Red flags that you're about to violate this:**

- "This tiny fix belongs in the last commit, I'll just amend it."
- "Amending keeps the history clean."
- "It was only pushed a minute ago, nobody has pulled it yet."
- "I'll amend now and deal with the push rejection later."
- "The commit message has a typo; a quick amend will fix it."
