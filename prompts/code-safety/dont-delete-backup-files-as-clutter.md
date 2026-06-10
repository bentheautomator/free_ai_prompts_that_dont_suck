---
title: Don't Delete Backup Files as Clutter
slug: dont-delete-backup-files-as-clutter
category: code-safety
tags: [universal, backups, files]
works_with: all
severity: critical
one_liner: "AI tidying away .bak files and old dumps that were the only safety net"
---

# Don't Delete Backup Files as Clutter

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting the safety copies — .bak files, .orig files, dated dumps, archive folders — during a cleanup pass.

**[Copy-paste ready version](../../install/dont-delete-backup-files-as-clutter.md)** — just the instruction block, no explanation.

## The Problem

To an AI doing a tidy-up, backup files are the most obviously deletable things in the tree. `config.yaml.bak`, `schema.orig`, `data_backup_2024/`, `export-final-OLD.json`, `dump-20250112.tar.gz` — they're duplicates by definition, often stale, frequently large, and they make directory listings ugly. So the cleanup pass removes them first. Which is exactly backwards: those files are the *only* copies that exist of previous states. Someone made each one on purpose, usually right before doing something risky, and "stale" is another word for "from before the change you might need to undo."

The AI's misread is treating backups as redundant with the current file. They're not redundant — they're the history. The current `config.yaml` doesn't contain what `config.yaml.bak` contains; that's the entire point of the `.bak`. Worse, backup files are often the last line of defense for things *outside* version control: data, dumps, configs with local values. Deleting the working copy of a tracked file costs a checkout. Deleting the `.bak` of an untracked file can cost the only path back from the next mistake — possibly a mistake the same AI is about to make.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It inverts the clutter heuristic.** The AI's tidy-up scoring marks backups as top deletion candidates; redefining them as "deliberate safety copies of states that no longer exist elsewhere" flips their value from negative to highest-in-directory.

2. **It offers tidiness without destruction.** Relocation into a `.backups/` folder satisfies the cleanliness goal that motivated the deletion, removing the trade-off entirely.

3. **It protects the last-copy invariant.** "Never delete the last backup of anything" is a checkable rule that survives even user-approved bulk cleanups, where the one irreplaceable file hides among twenty expendable ones.

## Origin

During a "clean up the project directory" task, an assistant deleted `settings.json.bak` and a `pre-migration-dump.tar.gz` as obvious cruft. Three days later, the migration that dump preceded turned out to have silently dropped a category of records, and the dump was the only copy of the pre-migration state. The person who'd made it had done everything right except predicting that the safety copy itself needed protecting.
