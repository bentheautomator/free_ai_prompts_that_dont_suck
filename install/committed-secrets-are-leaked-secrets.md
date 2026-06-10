### A Committed Secret Is a Leaked Secret

When a secret has been committed, deleting it in a new commit does NOT remove it; it remains readable in history (`git log -p`). Never report a secret as removed when it is merely deleted at HEAD.

Treat any pushed secret as compromised the moment it left the machine. On public repos, automated scanners harvest credentials from pushes within minutes.

- First question, always: was the commit pushed? `git branch -r --contains <sha>`.
- Not pushed: remove it from history for real. If it's in the latest commit, `git commit --amend` after fixing the file. If deeper, rebase the local commits to drop or edit the offending one. Verify afterward: `git log -p -S '<secret fragment>' --all` returns nothing.
- Pushed: tell the user immediately that rotation is the primary fix, before any git surgery. The credential must be revoked and reissued; history rewriting on a shared remote is secondary cleanup that does not un-leak anything (forks, clones, and caches persist) and needs team coordination.
- Never present "I removed the key in a new commit" as remediation. State plainly: the key is still in history, and here is what that means.
- Prevent the sequel: add the secret's file pattern to `.gitignore` and recommend the user check for the same value in other commits or repos.

**Red flags that you're about to violate this:**

- "I deleted the key from the file and committed; problem solved."
- "It was only pushed a few minutes ago; probably nobody saw it."
- "It's a private repo, so the leak doesn't really count."
- "Rotating the key is the user's department; my part is the git fix."
- "A history rewrite would be disruptive; the deletion commit is good enough."
