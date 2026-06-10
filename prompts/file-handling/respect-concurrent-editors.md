---
title: Respect Locks and Concurrent Editors
slug: respect-concurrent-editors
category: file-handling
tags: [universal, files, concurrency]
works_with: all
severity: medium
one_liner: "Stops stale-copy writes that erase changes made by humans or other tools"
---

# Respect Locks and Concurrent Editors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents writing a file from a stale in-memory copy, silently reverting edits made meanwhile by the user, a formatter, a watcher, or another agent.

**[Copy-paste ready version](../../install/respect-concurrent-editors.md)** — just the instruction block, no explanation.

## The Problem

An assistant reads `api.ts` early in a session, works on other things for ten minutes, then writes its planned change — composed against the version it read, not the version that now exists. In between, the user fixed a typo in their editor, or `prettier --write` ran on save, or a codegen watcher regenerated a section, or a second AI agent (increasingly common) edited the same file. The assistant's write is built from a stale snapshot; whatever happened in the gap is overwritten without a conflict marker, an error, or any trace beyond the user's dawning suspicion that their change "didn't take."

Humans get protected from this by editors that warn "file has changed on disk." Assistants have no such reflex by default: read-modify-write with an unbounded gap between read and write is the natural shape of their work, and the longer the session, the staler the snapshots. Lock files (`.~lock.*`, swap files, `package-lock` mid-install) signal active writers, and assistants routinely steamroll past those signals too.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Respect Locks and Concurrent Editors

NEVER write a file based on a stale read. If time, other commands, or another actor may have touched a file since you read it, re-read it before writing.

You are not the only writer. Users edit in parallel, formatters fire on save, watchers regenerate, and other agents act; a write composed from an old snapshot silently erases all of it.

- Re-read before write when there's a gap: if you read a file more than a few steps ago — or ran anything that could modify files (formatters, codegen, `npm install`, test runners with snapshot-update) — refresh before editing.
- Targeted edits beat whole-file writes here too: replacing a unique string fails loudly if the file changed underneath you (the anchor is gone); a full-file write from stale memory fails silently and destructively.
- If an edit fails because the expected text isn't there, that's evidence of concurrent change. Re-read and reconcile; never force the write or retry harder with a looser match.
- Treat lock artifacts as occupancy signals: `.~lock.*#` (LibreOffice), `.<name>.swp` (vim), `~$<name>` (Office). Don't edit the locked file and never delete the lock to get past it; ask, or wait.
- Mid-operation files are off limits: a lockfile during `npm install`, a database file under a running server, a log being written. Editing them races the owning process.
- After your write, if `git diff` shows reverted hunks you didn't intend — changes disappearing, not appearing — you clobbered someone. Restore their work first, then redo yours on top.

**Red flags that you're about to violate this:**

- "I read this file earlier; I know what's in it."
- "I'll write the version I've been planning." (Planned against what's still there?)
- "My string-replace didn't match, so I'll just rewrite the whole file."
- "That .swp file is probably leftover junk."
- "The user wouldn't edit while I'm working."

---

## Why It Works

1. **It bounds snapshot staleness**, the actual variable behind every lost-update bug: read-to-write gaps are fine at zero steps and dangerous at twenty, and the rule makes the re-read cost explicit and tiny.
2. **It exploits anchored edits as a free conflict detector.** A string-replace on vanished text fails loudly at exactly the right moment; the rule channels that failure into reconciliation instead of the catastrophic fallback (full rewrite from stale memory).
3. **Lost work destroys trust disproportionately:** a user whose typo fix gets silently reverted stops believing the diff, and re-auditing everything the assistant touched costs more than the original task.

## Origin

A developer fixed an off-by-one in a date helper while their assistant was mid-task on the same file. Four minutes later the assistant wrote its planned refactor — composed from a read that predated the fix — and the off-by-one returned to disk. It shipped, regressed a report, and got bisected to a commit that "shouldn't have touched that line," which was technically true: the line was reverted, not edited.
