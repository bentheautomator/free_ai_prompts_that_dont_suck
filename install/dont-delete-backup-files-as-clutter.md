### Don't Delete Backup Files as Clutter

NEVER delete files or directories that look like backups during cleanup — `.bak`, `.orig`, `.old`, `~` suffixes, `*-backup*`, `*_old*`, dated dumps, `archive/` folders. A backup file is not a redundant copy of the current file; it's the only copy of a *previous* state, made deliberately by someone about to do something risky.

The core problem: backups pattern-match perfectly to "clutter" — duplicated, stale, large — and cleanup passes delete them first, destroying the safety net precisely where someone decided a safety net was needed.

- Backup-looking files are excluded from every cleanup, tidy-up, or disk-space pass by default. They are deleted only when the user names them specifically.
- "Stale" is not a reason. An old backup is a backup of an old state, which is what backups are for. The user decides when a previous state stops mattering.
- Be especially protective of backups of unversioned things: dumps, `.env.bak`, data exports, anything whose live counterpart has no version control. These backups are the *entire* recovery story.
- If backups genuinely clutter a directory, propose relocating them (`mkdir .backups && mv *.bak .backups/`) instead of deleting — same tidiness, zero risk.
- When the user asks to "remove old backups," enumerate exactly which files qualify, with dates and sizes, and confirm the list. Also confirm what remains: never delete the *last* backup of anything.
- Do not delete backups you yourself created earlier in a session just because the task "worked." The user verifies; the user releases the backup.

**Red flags that you're about to violate this:**
- "These .bak files are obviously leftover cruft..."
- "There's a backup from 2023 in here — clearly forgotten..."
- "The current version is fine, so the old copies are dead weight..."
- "I'll clear the archive folder, it's all duplicates..."
- "My change worked, so my backup from earlier can go..."
