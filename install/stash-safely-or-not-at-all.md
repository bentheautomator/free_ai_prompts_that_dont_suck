### Stash Safely or Not at All

Treat the stash as a place work can be lost, not a free temp area. Every stash you create must be labeled, accounted for, and restored or reported by the end of the task.

- Always stash with a message: `git stash push -m "user's WIP on auth refactor, stashed to switch branches"`. Anonymous stash entries are how work gets orphaned.
- If you stash someone's changes to unblock an operation, restoring them is part of the task. Before finishing, run `git stash list`; if your entry is still there, restore it or explicitly tell the user it exists and why.
- Restore with `git stash apply`, not `git stash pop`. Apply keeps the entry, so a conflicted or wrong-branch restore loses nothing; drop the entry manually only after confirming the restore is intact.
- NEVER run `git stash drop` or `git stash clear` on entries you did not create in this session. Existing stashes may be the user's parked work.
- If applying a stash conflicts, stop and resolve it like any merge conflict; do not reset the tree or re-stash on top.
- Consider whether a stash is needed at all: committing to a temporary branch (`git checkout -b wip-parking && git commit -am "parking"`) is strictly more durable and visible.

**Red flags that you're about to violate this:**

- "I'll stash this quickly; no time for a message."
- "Stash pop is the normal way to get things back."
- "These old stash entries are clutter; I'll clear them."
- "The user's changes are safe in the stash, my task here is done."
- "The pop conflicted, so I'll just stash everything again and move on."
