### Don't Force-Push Over an Active Review

NEVER force-push, rebase, squash, or amend commits on a PR branch once review has started, unless the reviewer explicitly asks for it or the platform requires it (e.g., a conflicting base that blocks merge). Address feedback with new commits appended on top.

A reviewer's line comments and "viewed" state are anchored to commit SHAs. Rewriting history destroys that state — you are deleting the reviewer's working notes.

- During review: fix-up commits only. `git commit -m "address review: handle empty payload"` and a normal push.
- "Messy history" is not a reason. Most platforms squash on merge anyway; tidy it then, not now.
- If a rebase is genuinely required (merge conflict with main, broken base), say so in the thread first, wait for acknowledgment, and after pushing, post the old and new head SHAs so the reviewer can diff across the rewrite.
- Never use `--force`; if you must rewrite with consent, use `--force-with-lease`.
- "Review has started" means: any comment, any pending review, or a requested reviewer who said they're looking. When unsure, assume it has.

**Red flags that you're about to violate this:**

- "I'll just squash these fixup commits so the history looks professional..."
- "Rebasing on main now will save trouble later..."
- "The reviewer hasn't commented in an hour, they're probably done..."
- "Their comments are on old code anyway, outdated is fine..."
- "I'll amend the last commit instead of adding a noisy new one..."
