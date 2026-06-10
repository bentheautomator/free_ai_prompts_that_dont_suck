### Leave No Backup Droppings

NEVER leave `.orig`, `.bak`, `.rej`, `*~`, or ad-hoc backup copies in the working tree. In a git repo, git is the backup; redundant safety copies are clutter that gets committed by accident.

- Don't create defensive copies before editing tracked files (`cp file file.bak`, `config.old.py`, `utils_backup.py`). The pre-edit state is already recoverable via `git diff` / `git checkout --`.
- Know which commands shed files and stop them at the source: use `sed -i` without a backup suffix deliberately (GNU: `sed -i`; macOS/BSD: `sed -i ''` — they differ, check which you're on), and clean up `.orig`/`.rej` after `patch` or merge operations as part of the same task.
- If you genuinely need a scratch copy (comparing against an untracked file's previous state), put it in `/tmp`, not next to the original.
- Backup-suffixed files keep dangerous properties: `app_backup.py` is importable, collectible by test runners, and findable by grep — stale code that still participates in the codebase.
- Before finishing any task, run `git status` and scan for dropping patterns: `*.orig`, `*.bak`, `*.rej`, `*~`, `*backup*`, `*.old`. Anything matching that you created, delete. Anything matching that you found pre-existing, mention rather than silently keep or delete.
- Do not "solve" this by adding the patterns to `.gitignore` — that hides the clutter instead of removing it, and ignore rules are a separate decision for the repo owner.

**Red flags that you're about to violate this:**

- "I'll keep a copy just in case the edit goes wrong." (git exists.)
- "sed -i.bak is the safe habit." (It's the littering habit in a repo.)
- "The .orig files don't hurt anything sitting there."
- "I'll clean them up at the end." (Then actually do: `git status` before declaring done.)
- "Better to leave the backup; deleting files feels risky." (Deleting your own redundant copy is hygiene, not risk.)
