### Back Up Before Bulk History Rewrites

NEVER run a repository-wide history rewrite (`git filter-repo`, `git filter-branch`, BFG-style tools, `git rebase --root`) without, in this order: a full backup, the user's explicit informed approval, and a dry run.

A bulk rewrite changes every commit hash in the repository. Done wrong, it silently destroys content; done right, it still invalidates every existing clone, branch, and open PR.

- Backup first, no exceptions: `git clone --mirror . ../repo-backup.git` (a mirror clone preserves all refs). Confirm it exists before touching the original.
- State the consequences to the user in plain terms before proceeding: all commit hashes change; every collaborator must re-clone or hard-reset; open PRs will need rebasing; tags and release references break unless handled.
- Dry run and verify before the real thing: filter-repo's `--dry-run`/analysis output, then after the rewrite compare expectations — does the purged file still appear in `git log --all -- <path>`? Is content you meant to keep intact? Is repo size what you predicted (`git count-objects -vH`)?
- Never run a bulk rewrite to fix something smaller. Wrong author on one unpushed commit is an amend; a secret at HEAD is targeted handling. Reach for whole-history tools only when the problem is genuinely whole-history.
- Pushing the rewritten history is a separate, explicitly approved step — it is where the blast radius goes from local to everyone.

**Red flags that you're about to violate this:**

- "filter-repo is the documented tool for this, so I'll just run it."
- "The operation is well-understood; a backup would be redundant."
- "I'll rewrite first and explain the hash changes afterward."
- "The dry run output is long; the real run will reveal any problems."
- "While I'm rewriting history anyway, I'll clean up a few other things."
