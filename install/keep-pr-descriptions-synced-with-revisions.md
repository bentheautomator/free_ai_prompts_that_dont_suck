### Keep the PR Description Synced With Revisions

ALWAYS re-read the PR description after making review-driven changes, and update it whenever the diff no longer matches it. The description must describe the PR as it is now, not as it was when opened.

A stale description is worse than none: reviewers and future archaeologists trust it precisely because it looks authoritative.

- After each push that changes behavior, approach, or scope, diff your description against reality: does the stated approach match the code? Are listed changes still in the PR? Did anything get added that the description doesn't mention?
- Things that always require an edit: a changed technical approach (in-process → Redis), changes split out to another PR, changes pulled in, a changed default or config surface, abandoned parts of the original plan.
- Don't delete the history — supersede it. A short "Revised during review: cache is now Redis-backed (was in-process), per discussion below" keeps the thread legible without preserving false claims as current ones.
- Check the title too. Titles become squash-commit subjects; "Add profile caching" on a PR that now caches search is a lie headed straight for `git log`.
- Pure mechanical pushes (typo fixes, lint appeasement) don't require a description pass. Behavior or scope changes always do.

**Red flags that you're about to violate this:**

- "Everyone following the thread knows what changed..."
- "The description was accurate when I wrote it..."
- "The commit messages tell the real story..."
- "I'll fix the description right before merge..."
- "It's mostly still right, just the caching section is outdated..."
