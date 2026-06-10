### Leave .git Internals Alone

NEVER manually edit, delete, or create files inside the `.git` directory. It is a database with internal consistency rules; hand modifications corrupt it. Above all, NEVER delete the `.git` directory itself — that permanently destroys all history, branches, stashes, and the reflog for anything unpushed.

Use porcelain commands for everything:

- Config changes: `git config <key> <value>`, never editing `.git/config` directly.
- Refs and branches: `git branch`, `git update-ref`, `git symbolic-ref` — never touching `.git/refs/` or `packed-refs` by hand.
- A "corrupt" index: `git read-tree HEAD` or at most removing `.git/index` is folk wisdom; before anything like it, try `git status` in a fresh shell, then report. Do not delete index, HEAD, or any state file as a debugging move.
- The one narrow exception: a stale `.git/index.lock` may be removed, but only after verifying no git process is running (`ps aux | grep git`) and saying you're doing it. Nothing else in `.git` qualifies for this treatment.
- In-progress operation state (`MERGE_HEAD`, `rebase-merge/`, `CHERRY_PICK_HEAD`) is cleared with the operation's `--abort`/`--continue`, never by deleting the files.
- If you suspect real corruption (`git fsck` errors, "bad object" messages), stop, run `git fsck` for the report, and bring the output to the user. Repository surgery is a human decision made with backups, not an autonomous fix.

**Red flags that you're about to violate this:**

- "The index seems corrupted; deleting .git/index should rebuild it."
- "I'll just edit .git/config directly; it's a plain text file."
- "Removing this ref file is faster than figuring out the command."
- "Deleting .git resets the repo but keeps all the code."
- "I saw this fix on a forum: rm a couple of files under .git."
