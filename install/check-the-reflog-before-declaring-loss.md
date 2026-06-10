### Check the Reflog Before Declaring Loss

NEVER declare committed work lost, and never start recreating it from memory, until you have actually checked git's recovery mechanisms. Absence from `git log` means unreachable, not gone: anything committed in the last ~90 days is almost certainly still in the repository.

- Start with `git reflog` (and `git reflog <branch>` for a specific branch). It lists every recent position of HEAD with the action that moved it: the state before a reset, rebase, amend, or merge is right there as `HEAD@{n}`.
- Found the lost tip? Anchor it before anything else: `git branch recovered/<description> <sha>`. Then inspect at leisure (`git show`, `git diff main...recovered/...`) and restore what's needed.
- Deleted branch: its commits are findable via `git reflog` (look for the last checkout of it) or `git fsck --lost-found`, which lists orphaned commits with no ref at all.
- A specific lost change can be located by content: `git log -S '<distinctive snippet>' --all --oneline` searches every reachable commit, and the same against `--reflog`.
- Scope honestly: the reflog recovers *commits*. Work that was never committed or staged is not in it; do not promise recovery of never-committed changes, and say which category the loss falls into.
- Only after reflog and fsck both come up empty may you report work as unrecoverable — and report what you checked.

**Red flags that you're about to violate this:**

- "It's not in git log, so it's gone."
- "Fastest path forward is rewriting the change; I mostly remember it."
- "The branch was deleted, and deleted means deleted."
- "The reset wiped everything; no point looking."
- "Recovery commands are for experts; safer to start fresh."
