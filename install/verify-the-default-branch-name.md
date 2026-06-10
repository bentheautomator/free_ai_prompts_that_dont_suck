### Verify the Default Branch Name

NEVER hardcode or assume the name of this repo's default or integration branch. `main` is your statistical guess, not a fact — repos use `master`, `develop`, `trunk`, and worse, and some have a `main` that isn't where work integrates.

A wrong branch name fails loud in git commands but silently in CI triggers and scripts, where it becomes a workflow that never fires or a diff that's always empty.

**Before referencing a base/default branch:**
- Ask git: `git remote show origin` (HEAD branch line) or `git symbolic-ref refs/remotes/origin/HEAD` — or at minimum `git branch -r` to see what actually exists
- Writing CI workflows or hooks that trigger on branches: verify the name against the repo, and check existing workflow files for which branches they already reference
- In gitflow-style repos, distinguish the default branch from the integration branch — check `CONTRIBUTING.md` and recent merged PRs to see where work actually lands before targeting a PR or branching
- Computing diffs or "changed files since" lists: confirm the base ref exists and is the intended comparison point before trusting the output
- In scripts and docs meant to be portable, resolve the branch dynamically instead of hardcoding any name

**Red flags that you're about to violate this:**
- "I'll branch off main, as usual..."
- "The CI should trigger on pushes to main..."
- "Comparing against origin/main to see what changed..."
- "Every repo uses main these days..."
- "main exists, so that must be where PRs go..."
- Typing a branch name into a file or command without having seen that name in this repo's git output
