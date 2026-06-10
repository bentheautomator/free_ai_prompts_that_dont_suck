---
title: Verify Copies Before Deleting Originals
slug: verify-copies-before-deleting-originals
category: code-safety
tags: [universal, files, data]
works_with: all
severity: critical
one_liner: "AI deleting source files after a copy or move it never verified"
---

# Verify Copies Before Deleting Originals

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting source data on the strength of a copy operation it assumed succeeded.

**[Copy-paste ready version](../../install/verify-copies-before-deleting-originals.md)** — just the instruction block, no explanation.

## The Problem

"Move these files to the archive server" decomposes into copy-then-delete, and the AI performs both halves back to back: `scp -r data/ server:/archive/ && rm -rf data/`. The copy "succeeded" — exit code zero — so the delete proceeds. But exit code zero from a recursive copy means the command finished, not that every byte arrived: partial transfers on dropped connections (depending on tool and flags), files skipped over permissions, symlinks copied as links to targets that don't exist remotely, an out-of-space condition that truncated the last files, or the classic — the copy landed in the wrong remote directory, fully successfully. The delete doesn't care about any of this. The originals are gone, and what's on the other side is whatever fraction made it.

The AI chains these steps because the task said "move," and move means the source ends up gone. But between copy and delete sits the only moment when both copies exist — the one moment verification is free and mistakes are reversible. Skipping it converts every copy-time problem, silent or loud, into permanent data loss. Real migrations are paranoid here for a reason: the delete is the commit point, and you don't commit what you haven't checked.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Copies Before Deleting Originals

NEVER delete source files on the strength of a copy command's exit code. Between copy and delete is the only moment when both copies exist and mistakes cost nothing — verification happens there, every time.

The core problem: "move" decomposes into copy-then-delete, and a copy can finish (exit 0) while being incomplete or mislocated — partial transfers, skipped files, truncation on full disks, or a flawless copy into the wrong destination. The delete makes whatever happened permanent.

- Verify by comparison, not by exit code. Minimum bar: file counts and total bytes on both sides (`find ... | wc -l`, `du -sb`). Better: checksums (`rsync -c --dry-run` reports differences; `diff -r` for local; checksum manifests for remote).
- Verify the *destination is where you think*: list the remote/target path and confirm the files are actually in it — not one level up, not in a directory that auto-created with a different name.
- Open one or two transferred files. A correct-size unreadable file (encoding, truncation, copied symlink) passes count checks and fails reality.
- Keep the delete as a separate, later step — never `&&`-chained to the copy. Ideally let originals survive until the destination has been *used* successfully once, and let the user fire the deletion.
- For large or important moves, prefer tools that verify as they go (`rsync` with `--checksum` over bare `scp -r`) and that report what was skipped.
- If verification finds any discrepancy — one missing file, one size mismatch — nothing gets deleted until it's explained and fixed.

**Red flags that you're about to violate this:**
- "Copy returned success, so I can clear the source now..."
- "I'll chain the rm so the move completes in one command..."
- "Counting files on both ends is excessive for a simple transfer..."
- "The tool would have errored if anything was missing..."
- "It's a move operation, deleting the source is just finishing the job..."

---

## Why It Works

1. **It identifies the free-verification window.** "The only moment when both copies exist" gives the pause a concrete reason located in time — checks before the delete cost nothing, the same checks after are forensics.

2. **It downgrades exit codes from proof to rumor.** Listing the ways exit-0 copies lose data (partial, skipped, truncated, mislocated) breaks the success-code inference the AI's chaining depends on.

3. **It unchains the commit point.** Forbidding `copy && delete` as a single unit structurally inserts the gap where verification — and human review — can happen.

## Origin

Asked to migrate a recordings folder to network storage before a laptop was returned, an assistant ran the copy, saw success, and deleted the local originals. The network share had auto-disconnected partway through; the copy had cheerfully continued into a local mount-point directory that vanished on the next reboot. Sixty interview recordings existed for one afternoon in two places, then nowhere. A `du -sh` on the destination would have read 0 before the delete ran.
