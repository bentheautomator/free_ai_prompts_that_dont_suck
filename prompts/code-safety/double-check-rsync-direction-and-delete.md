---
title: Double-Check Rsync Direction and Delete Flags
slug: double-check-rsync-direction-and-delete
category: code-safety
tags: [universal, files, sync]
works_with: all
severity: critical
one_liner: "AI swapping rsync source and destination, or syncing deletions the wrong way"
---

# Double-Check Rsync Direction and Delete Flags

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running a sync that flows the wrong direction and overwrites the good copy with the bad one.

**[Copy-paste ready version](../../install/double-check-rsync-direction-and-delete.md)** — just the instruction block, no explanation.

## The Problem

Sync tools have a direction, and the direction is encoded in nothing but argument order. `rsync -av --delete server:/data/ ./data/` restores from the server. `rsync -av --delete ./data/ server:/data/` destroys the server copy with whatever's local — including, with `--delete`, removing every server file that doesn't exist locally. Same characters, opposite catastrophe. AI assistants generate these commands fluently and get the order wrong at a meaningful rate, because "sync A and B" in the task description carries no direction at all, and the model picks one.

Trailing slashes add a second trap: `rsync src dest` and `rsync src/ dest` put files in different places, which is how you end up with `data/data/` or with files sprayed into a parent directory. Combine a guessed direction, a guessed slash, and `--delete`, and the AI is one Enter away from making the empty side authoritative. The freshly created, still-empty local directory becomes the source of truth, and the tool faithfully deletes everything on the other end to match it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Double-Check Rsync Direction and Delete Flags

Before any sync command, ALWAYS state which side is the source of truth and which side gets destroyed to match it. Never run a sync whose direction you inferred rather than confirmed.

The core problem: direction lives entirely in argument order — `rsync --delete A B` and `rsync --delete B A` are opposite disasters — and task phrasing like "sync the data" specifies no direction at all.

- Write it out before running: "SOURCE (authoritative): X. DESTINATION (will be made to match, losing anything extra): Y." If the user's request doesn't determine this, ask.
- Sanity-check the source is the *fuller, fresher* side: compare file counts or sizes (`ls | wc -l`, `du -sh`) on both ends first. An empty or near-empty source plus `--delete` means you're about to erase the destination.
- Treat `--delete` (and `--delete-after`, `--mirror` in other tools) as a separate decision from the sync itself. Only add it when the user explicitly wants extraneous destination files removed.
- Run with `--dry-run` first and read the deletions it reports, not just the transfers.
- Verify trailing-slash behavior: `src/` copies contents, `src` copies the directory itself. Get it wrong and files land one level off — or deletions apply one level wider.
- The same applies to `scp -r`, `aws s3 sync`, `gsutil rsync`, `robocopy /MIR`: same direction trap, same rules.

**Red flags that you're about to violate this:**
- "Sync them up — order probably doesn't matter much here..."
- "I'll mirror with --delete so the two sides match exactly..."
- "The local copy must be the newer one..."
- "I just created the destination folder, now sync into... wait, which way..."
- "Trailing slash details are a nitpick, rsync will figure it out..."

---

## Why It Works

1. **It forces direction into words.** "Source of truth / side that gets destroyed" is a sentence the AI cannot complete from an ambiguous request — completing it requires either checking state or asking, both of which prevent the guess.

2. **It adds an emptiness check.** The fatal pattern is syncing *from* the empty side. Comparing sizes first catches inverted direction even when the AI's reasoning was confidently wrong.

3. **It decouples `--delete` from sync.** The AI adds `--delete` for tidiness, as part of "doing a proper sync." Making it a separate, user-authorized decision strips it out of the default command shape.

## Origin

Asked to "sync the backup folder with the NAS," an assistant created a fresh local `backup/` directory and ran rsync with `--delete` — local side first. The NAS directory, holding the only copy of two years of archived project files, was dutifully emptied to match the brand-new empty folder. A dry run would have printed two thousand `deleting` lines; a size check would have shown 0 bytes syncing onto 400 GB.
