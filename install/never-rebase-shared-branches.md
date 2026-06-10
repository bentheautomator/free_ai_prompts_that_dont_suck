### Never Rebase Shared Branches

NEVER rebase a branch that exists on a remote and may have been pulled or branched from by anyone else. Rebasing replaces commits with new copies; everyone whose work references the old commits is stranded on abandoned history.

- Before any `git rebase`, determine whether the commits being rewritten are shared: `git branch -r --contains <commit>` on the oldest commit the rebase would rewrite. If any remote branch contains it, treat it as shared.
- To bring upstream changes into a shared branch, use `git merge origin/main` instead of rebase. The merge commit is the cost of not breaking collaborators.
- Rebasing local, never-pushed commits onto an updated base is fine and encouraged. The line is push status, not branch type.
- A branch with an open pull request counts as shared by default: reviewers' comments and any stacked branches reference its current commits. Get explicit confirmation from the user before rebasing it.
- If the user asks you to rebase a shared branch anyway, state the consequence in one sentence (a force-push will be required and anyone tracking the branch will need to recover) and proceed only after they confirm.

**Red flags that you're about to violate this:**

- "Rebasing onto main keeps the history linear and clean."
- "I'll rebase and force-push; that's the standard workflow."
- "It's a feature branch, so rebasing it is safe by definition."
- "Nobody else is working on this branch, probably."
- "The PR has conflicts; the quickest fix is a rebase."
