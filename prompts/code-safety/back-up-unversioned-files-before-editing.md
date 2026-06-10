---
title: Back Up Unversioned Files Before Editing Them
slug: back-up-unversioned-files-before-editing
category: code-safety
tags: [universal, files, backups]
works_with: all
severity: high
one_liner: "AI editing files with no version control and no way back"
---

# Back Up Unversioned Files Before Editing Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from modifying files that have no undo — no version control, no snapshot, nothing.

**[Copy-paste ready version](../../install/back-up-unversioned-files-before-editing.md)** — just the instruction block, no explanation.

## The Problem

Most of an AI assistant's edits land on tracked source files, where every mistake is one `git diff` from visible and one checkout from gone. That safety net trains a habit: edit freely, verify after. Then the same habit gets applied to `.env`, to a Jupyter notebook with six hours of un-exported analysis, to `~/.ssh/config`, to a server's nginx conf, to the one YAML file that's gitignored because it contains machine-specific values. The edit goes wrong — or just goes differently than expected — and there is no previous version. Anywhere.

The AI doesn't distinguish these cases because the edit operation looks identical. Whether a file is under version control is invisible at the moment of editing unless you check. And the files that aren't tracked are disproportionately the ones that hurt: local configs tuned over months, notebooks holding unreproduced results, credentials files, data files. Gitignored is usually a synonym for "irreplaceable and uncopied."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It makes the safety net a checked fact, not an assumption.** The AI's edit confidence is calibrated on version-controlled files. Forcing an explicit tracking check recalibrates per file, exactly where the assumption fails.

2. **It costs almost nothing, which kills the counterargument.** A `cp` before editing is one command. By specifying the exact cheap mechanism, the rule removes "it's not worth the overhead" as a viable rationalization.

3. **It covers the uncommitted-changes blind spot.** Half the real losses are tracked files carrying someone's uncommitted work. Naming that case extends protection to files that look safe by the tracking check alone.

## Origin

An assistant updated a gitignored `settings.local.yaml` to point a service at a new endpoint. The edit also "normalized" the rest of the file, silently dropping a block of hand-tuned worker parameters that had been arrived at over months of incidents. No backup, no version control, no copy on any machine. The team reconstructed the values from an old screenshot in a chat thread, which is not a backup strategy anyone recommends.
