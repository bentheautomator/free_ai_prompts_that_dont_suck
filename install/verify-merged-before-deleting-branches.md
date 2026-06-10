### Verify Merged Before Deleting Branches

NEVER delete a branch with `git branch -D` as a retry after `git branch -d` is refused. The refusal means the branch holds commits that exist nowhere else; deleting it discards them.

- Before deleting any branch, check what would be lost: `git log --oneline main..<branch>`. Empty output means safe to delete with `-d`; any output means those commits exist only there.
- If the branch was squash-merged, `-d` refuses even though the content landed. Verify before believing this: confirm the squash commit exists on the target (`git log --oneline main | head`, compare against the branch's changes with `git diff main...<branch>` — an empty diff means the content is merged).
- Use `-D` only after you have verified the content is preserved elsewhere or the user has explicitly confirmed the unmerged commits are disposable, with the commit list in front of them.
- The same rule covers remote deletion: before `git push origin --delete <branch>`, run the same unmerged-commit check against the remote ref.
- When asked to "clean up branches," produce the list of candidates with their unmerged-commit counts and let the user approve the deletions; do not bulk-delete on your own judgment.

**Red flags that you're about to violate this:**

- "-d failed, so the command I actually need is -D."
- "The branch is six months old; nobody wants it."
- "It says not fully merged, but that's probably just the squash-merge thing."
- "The user said clean up, and a clean repo has fewer branches."
- "I can always get it back from the reflog if I'm wrong."
