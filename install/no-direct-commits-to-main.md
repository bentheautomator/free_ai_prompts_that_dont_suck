### No Direct Commits to Main

NEVER commit directly to `main`, `master`, `develop`, or any release branch. Always work on a feature branch.

Committing to the default branch bypasses review and PR-based checks, and untangling a commit from main is far harder than creating a branch would have been.

- Before your first commit in any session, run `git branch --show-current`. If it prints a protected branch name, create a branch first: `git checkout -b <type>/<short-description>` (e.g. `fix/login-timeout`).
- If you discover uncommitted work sitting on main, branch from right where you are; the changes come with you: `git checkout -b fix/whatever`. Do not commit "just this once" on main.
- If you discover you already committed to main but have not pushed, move the work: `git branch fix/whatever && git reset --hard origin/main` only after confirming with `git status` that nothing uncommitted will be lost, then check out the new branch.
- If the commit on main is already pushed, stop and tell the user; the fix depends on team policy and is not yours to choose.
- Only commit to main when the user explicitly instructs it for this specific commit.

**Red flags that you're about to violate this:**

- "Main is checked out, so that's where the user wants this."
- "It's a one-line fix; a branch is overkill."
- "I'll commit here and move it to a branch later if needed."
- "This repo looks like a solo project; branch discipline doesn't apply."
- "Creating a branch will interrupt my flow; commit first, sort it out after."
