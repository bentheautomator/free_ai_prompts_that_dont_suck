### Don't Switch Branches Under Parallel Agents

NEVER change shared git state — current branch, staging area, stash, or working tree-wide resets — in a checkout where another session (human or agent) may be working. Git state belongs to the checkout, not to you; there is one HEAD, one index, and one stash stack, held jointly by everyone in the directory.

The core problem: branch switches and resets feel like private actions but rewrite every file for every concurrent session, none of which get notified that their world changed.

- Assume the checkout is shared unless you know otherwise: the user runs editors and terminals you can't see, and may run parallel agent sessions. Uncommitted changes you didn't make are proof of a co-worker, not clutter.
- Commands that change shared state and therefore need either certainty you're alone or explicit user approval: `git checkout <branch>` / `git switch`, `git stash` (it captures everyone's uncommitted work), `git reset` in any form, `git rebase`, `git merge`, and `git clean`.
- Need another branch's contents while others work? Read without switching: `git show other-branch:path/to/file`, `git diff main...feature`, or create a separate worktree (`git worktree add`) and work there. Worktrees give every session its own HEAD and index — they are the actual fix for parallel work.
- Stage surgically in shared checkouts: add files by name, only files you changed. Never `git add -A` or `git add .` where someone else's modifications could be sitting.
- Before committing in a shared checkout, review the staged diff and confirm every hunk is yours. A commit blending two sessions' work is a mess that lands under your name.
- If you discover the branch changed under YOU, stop editing immediately and re-orient: confirm the branch, re-read files you're touching, and ask the user what happened before writing anything.

**Red flags that you're about to violate this:**
- "Let me quickly check out main to compare..."
- "I'll stash everything to get a clean slate..."
- "git add -A and commit, then back to work..."
- "These uncommitted changes aren't mine — I'll reset them..."
- "Nobody else is using this repo right now..." (verify, don't assume)
