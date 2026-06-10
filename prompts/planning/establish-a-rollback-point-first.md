---
title: Establish a Rollback Point First
slug: establish-a-rollback-point-first
category: planning
tags: [universal, planning, safety]
works_with: all
severity: high
one_liner: "Three hours into a big change with no clean state to retreat to"
---

# Establish a Rollback Point First

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents starting a large or risky change without a known-good state you can cheaply return to.

**[Copy-paste ready version](../../install/establish-a-rollback-point-first.md)** — just the instruction block, no explanation.

## The Problem

The assistant starts a sweeping refactor on top of a working tree that already has uncommitted changes in it — the user's half-finished work, or its own from the previous task. Twenty files later, the refactor turns out to be a dead end. Now what? There's no commit to reset to. The good changes and the bad changes are interleaved in the same dirty tree, and "undo the refactor" becomes a manual, file-by-file untangling job where every mistake destroys work someone wanted to keep.

Assistants skip the rollback point because creating one produces nothing visible. A `git commit` or `git stash` before starting doesn't advance the task; it's pure insurance, and insurance only looks smart in the timeline where things went wrong. But large changes go wrong at a rate that makes the ten-second checkpoint one of the best trades available — the difference between "abandon this approach" being a one-command decision versus a salvage operation.

The deeper cost is decision distortion. Without a cheap retreat, abandoning a failing approach means losing everything, so the assistant doubles down on approaches it would otherwise drop. The rollback point doesn't just protect the code; it keeps "start over" on the table as a rational option.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Establish a Rollback Point First

NEVER begin a large, sweeping, or experimental change without first securing a state you can return to with one command. If you can't answer "how do I get back to right now?" in one sentence, you're not ready to start.

The core problem: checkpoints produce nothing visible, so they get skipped — until the approach fails and "undo it" means manually untangling good changes from bad in a dirty tree.

- Before a multi-file change, check `git status`. A dirty tree gets committed, stashed, or explicitly acknowledged with the user before you pile new changes on top of it.
- Make the checkpoint real: a commit on a branch, a stash, a tag — something addressable, not "I remember what the files looked like."
- For changes outside version control (database schemas, config files on servers, generated assets), the rollback point is a dump, a copy, or a documented reverse procedure. Confirm it exists before the forward step.
- Scale it to the risk: a one-file edit needs nothing; a 20-file refactor needs a commit; an irreversible operation needs a verified backup.
- When an approach fails, actually use the rollback. Resetting to the checkpoint and rethinking beats hand-reverting on top of the wreckage.

**Red flags that you're about to violate this:**
- "I'll commit once it's working..."
- "The working tree has some changes but they shouldn't interfere..."
- "Git has my back somehow if this goes wrong..." (uncommitted means it doesn't)
- "This refactor will definitely land, no need for a safety net..."
- "I can always undo my edits by hand..."

---

## Why It Works

1. **It makes retreat cheap, which makes retreat thinkable.** When abandoning costs one command, failing approaches get abandoned at the right time. When abandoning costs an afternoon, they get doubled down on.

2. **It separates the layers.** A commit boundary between pre-existing work and the new change means the new change can be removed surgically. Interleaved in one dirty tree, removal endangers everything.

3. **It converts "known-good" from memory to address.** "I remember it worked" degrades over twenty files of edits; a commit hash doesn't.

4. **It extends the habit past git.** The explicit rule for schemas and configs covers exactly the changes where there is no reflog to save you.

## Origin

An assistant began converting a codebase to a new dependency-injection pattern on a tree that held the user's uncommitted bugfix across six files. The conversion failed in the entrypoint wiring and had to be abandoned — but `git checkout .` would have destroyed the bugfix too. Untangling the two changesets by hand took longer than the conversion attempt itself, and one file of the bugfix was reverted by mistake, re-introducing the original bug a week after everyone believed it fixed.
