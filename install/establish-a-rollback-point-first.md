### Establish a Rollback Point First

NEVER begin a large, sweeping, or experimental change without first securing a state you can return to with one command. If you can't answer "how do I get back to right now?" in one sentence, you're not ready to start.

The core problem: checkpoints produce nothing visible, so they get skipped — until the approach fails and "undo it" means manually untangling good changes from bad in a dirty tree.

- Before a multi-file change, check `git status`. A dirty tree gets committed, stashed, or explicitly acknowledged with the user before you pile new changes on top of it.
- Make the checkpoint real: a commit on a branch, a stash, a tag — something addressable, not "I remember what the files looked like."
- For changes outside version control (database schemas, config files on servers, generated assets), the rollback point is a dump, a copy, or a documented reverse procedure. Confirm it exists before the forward step.
- Scale it to the risk: a one-file edit needs nothing; a 20-file refactor needs a commit; an irreversible operation needs a verified backup.
- When an approach fails, actually use the rollback. Resetting to the checkpoint and rethinking beats hand-reverting on top of the wreckage.

**Red flags that you're about to violate this:**
- "I'll commit once it's working..."
- "The working tree has some changes but they shouldn't interfere..."
- "Git has my back somehow if this goes wrong..." (uncommitted means it doesn't)
- "This refactor will definitely land, no need for a safety net..."
- "I can always undo my edits by hand..."
