---
title: Leave No Backup Droppings
slug: leave-no-backup-droppings
category: file-handling
tags: [universal, files, hygiene]
works_with: all
severity: medium
one_liner: "Stops .orig, .bak, and editor leftovers from littering the working tree"
---

# Leave No Backup Droppings

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tool-generated leftovers — `.orig`, `.bak`, `.rej`, `~` files, sed backups — from being created carelessly and left in the working tree.

**[Copy-paste ready version](../../install/leave-no-backup-droppings.md)** — just the instruction block, no explanation.

## The Problem

Tools shed files. `git merge` leaves `.orig` files when configured to, failed `patch` applications leave `.rej` and `.orig`, `sed -i.bak` leaves `.bak` (and on macOS, `sed -i ''` vs GNU `sed -i` confusion produces backups named after the script's next argument), and defensive copies like `cp config.py config.py.backup` get made "just in case" and never removed. Each dropping is harmless until it isn't: `app.py.bak` still matches `import`-adjacent glob patterns and some build globs (`**/*.py` collects it if it kept the extension... and `app.py.bak` didn't, but `app_backup.py` did), search results return two versions of every function, and a future maintainer wastes real time deciding which copy is the truth.

The deeper failure: an assistant that makes a `.backup` copy before editing is substituting a worse mechanism for the one already present. The repo is version controlled. `git diff` and `git checkout --` are the undo story; a scattered shadow-copy system on top of git is clutter that can itself get committed — and routinely does, via `git add .`.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It replaces a bad backup system with the good one already running.** Shadow copies next to originals are strictly worse than git on every axis — discoverability, restore, and cleanliness — so the rule removes work rather than adding it.
2. **It names why droppings are active hazards, not passive mess:** backup files with live extensions keep getting imported, collected, grepped, and committed. The cost isn't aesthetic.
3. **The end-of-task `git status` scan is a closed loop.** A finite pattern list against actual command output beats remembering what every tool shed along the way.

## Origin

A hotfix session left `payment_handler.py.orig` from a conflicted patch in the services directory. Months later, a grep-driven refactor updated a function signature in both files — and a junior engineer, finding two handlers, "fixed" the import to point at the `.orig` one because its code looked simpler. Code review caught it, but the review thread about which file was real ran longer than the refactor diff.
