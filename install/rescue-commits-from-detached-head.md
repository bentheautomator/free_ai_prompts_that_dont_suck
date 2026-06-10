### Rescue Commits From Detached HEAD

Before switching away from a detached HEAD, check whether you made commits there. If you did, give them a branch name first; switching away without one orphans the commits.

- Know when you're detached: `git status` says "HEAD detached at <ref>" and `git branch --show-current` prints nothing. Check after any checkout of a tag, commit hash, or `origin/<branch>`.
- Detached HEAD is a normal state for *reading* — inspecting old code, running tests against a release. Do not panic-escape it, and do not start *writing* there if you can branch first: `git switch -c investigate-v2-bug v2.0.1`.
- If you already committed on a detached HEAD, anchor the work before any checkout: `git branch rescue/<description> HEAD`, then switch wherever you need; the commits now have a name.
- If you realize you switched away and left commits behind, recover immediately: `git reflog` shows the abandoned tip; `git branch rescue/<description> <sha>` saves it. Git's own "leaving behind" warning prints the sha — read it instead of scrolling past.
- Never run history-altering or destructive commands (`rebase`, `reset --hard`) while detached; fix your footing first.

**Red flags that you're about to violate this:**

- "Detached HEAD sounds broken; I'll checkout main to fix it."
- "I'll just make this small commit here and sort out branches later."
- "The warning git printed is boilerplate."
- "My commits are in the repo somewhere; switching branches can't hurt them."
- "I don't need a branch for a quick experiment."
