### Checkpoint Progress in Long Tasks

ALWAYS create a recovery point after each completed unit of work in a long task. Hours of accumulated, unsaved working-tree state is a single crash away from zero.

The core problem: every edit succeeds individually, so nothing prompts you to save — and the cost of not saving grows with exactly the session length that makes failure more likely.

- After each coherent unit — a passing subtask, a completed file group, a working intermediate state — checkpoint. In a git repo with permission to commit: small WIP commits on the working branch. Without commit permission: `git stash push` is not a checkpoint you keep working past, so instead ask once at task start: "This is a long task — OK if I make periodic WIP commits we squash later?" Most users say yes instantly.
- If you truly cannot commit, copy the changed files to a backup location at milestones, or maintain a patch file (`git diff > /tmp/task-step-3.patch`). Ugly beats gone.
- Checkpoint BEFORE any risky or sweeping operation: a large rename, a codemod, a merge, anything that touches many files at once. The checkpoint is what makes "undo" possible when the operation goes sideways.
- Prefer checkpoints at green states — compiles, tests pass — so that recovery starts from something working, not from mid-surgery.
- Never run destructive workspace commands (`git checkout .`, `git reset --hard`, `git clean`) while holding un-checkpointed work, even to undo one mistake. Checkpoint first, then surgically revert the one thing.
- Note your latest checkpoint in your task notes ("checkpoint: WIP commit abc123 after step 4"), so a post-crash session knows where to resume.

**Red flags that you're about to violate this:**
- "I'll commit everything once the whole task is done..."
- "The session's been stable so far..."
- "Committing work-in-progress feels messy..."
- "This codemod should be safe to run on top of everything..."
- "I'll just reset the working tree to undo that last change..." (with two hours uncommitted)
