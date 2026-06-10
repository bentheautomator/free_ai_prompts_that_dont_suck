### Back Up Unversioned Files Before Editing Them

Before modifying any file, know whether it has an undo. If a file is not under version control — gitignored, outside the repo, or in an untracked state — ALWAYS create a timestamped backup copy before the first edit.

The core problem: editing habits formed on tracked files (where git is the safety net) get applied to untracked ones, and untracked files are disproportionately the irreplaceable ones — local configs, notebooks, `.env` files, machine-specific settings.

- Check tracking status before editing: is the file in the repo and committed? `git ls-files --error-unmatch <file>` or a glance at `.gitignore` answers it.
- For any unversioned file, copy first: `cp config.yaml config.yaml.bak-$(date +%Y%m%d%H%M%S)`. Then edit.
- Treat these as unversioned-by-default: `.env*`, notebooks, files in `$HOME`, anything matched by `.gitignore`, files on remote servers, databases and data files of any kind.
- Tracked-but-modified counts too: if a file has uncommitted changes you didn't make, those changes are as unprotected as an untracked file. Preserve them (backup copy or ask the user to commit/stash) before layering your edits on top.
- Tell the user where the backup is, and don't delete backups you created — let the user decide when they're safe to remove.
- If you can't write a backup (permissions, read-only filesystem), that's a reason to pause, not to proceed without one.

**Red flags that you're about to violate this:**
- "It's a small config tweak, hardly worth a backup..."
- "I'll remember what the original values were..."
- "The file's probably in git like everything else here..."
- "Backing up first doubles the steps for a one-line change..."
- "If it breaks, we can reconstruct it from the docs..."
