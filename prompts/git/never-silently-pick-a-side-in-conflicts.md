---
title: Never Silently Pick a Side in Merge Conflicts
slug: never-silently-pick-a-side-in-conflicts
category: git
tags: [universal, git]
works_with: all
severity: critical
one_liner: "Stops conflict resolution that quietly discards one side's changes"
---

# Never Silently Pick a Side in Merge Conflicts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from resolving merge conflicts by keeping one side wholesale and throwing the other side's work away without telling anyone.

**[Copy-paste ready version](../../install/never-silently-pick-a-side-in-conflicts.md)** — just the instruction block, no explanation.

## The Problem

A merge conflict means two sets of changes touched the same lines and both were made for a reason. AI assistants under pressure to "finish the merge" resolve conflicts with `git checkout --ours`, `git checkout --theirs`, or by deleting one side's hunk in the editor, because that makes the conflict markers disappear fastest. The merge completes, tests on the surviving side pass, and the other side's bug fix or feature quietly ceases to exist.

This is the nastiest failure in this category because it leaves no error. The commit is green, the history looks normal, and the deleted work isn't discovered until the bug it fixed comes back or the feature it added is reported missing — sometimes weeks later, when nobody remembers the merge. Tools like `-X ours`/`-X theirs` make it worse by silently resolving *every* conflict the same direction in bulk.

Assistants do this because conflict markers read as errors to be eliminated, and the success signal they optimize for is "merge completed," not "both intents preserved."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Silently Pick a Side in Merge Conflicts

NEVER resolve a merge conflict by mechanically keeping one side. Both sides of a conflict were written deliberately; a resolution must preserve the intent of both or explicitly justify dropping one.

- Banned as default moves: `git checkout --ours <file>`, `git checkout --theirs <file>`, `git merge -X ours`, `git merge -X theirs`, and hand-deleting one side's hunk without reading it.
- For each conflicted file, read both sides and state what each was trying to do. Then construct a resolution that preserves both intents; usually this means combining the changes, not choosing.
- If both intents genuinely cannot coexist (e.g., two different fixes for the same bug), choose deliberately and say so: report which side you dropped, what it contained, and why.
- After resolving, search the file for leftover markers (`<<<<<<<`, `=======`, `>>>>>>>`) and re-run the relevant tests for both sides' changes if they exist.
- If a conflict is too tangled to resolve confidently, stop and present both sides to the user instead of guessing. An aborted merge (`git merge --abort`) is recoverable; silently destroyed work is not.

**Red flags that you're about to violate this:**

- "Our version is newer, so theirs is outdated."
- "Taking --theirs for the whole file resolves all six conflicts at once."
- "The tests pass after keeping our side, so the resolution is correct."
- "The other side's change looks unrelated to what I'm doing."
- "I need this merge finished; I'll keep the simpler side."

---

## Why It Works

1. **It redefines what a conflict is.** The AI treats markers as syntax errors to delete; the rule reframes them as two valid intents requiring synthesis, which changes the goal from "make markers go away" to "preserve both changes."
2. **Forcing a stated summary of each side makes silent deletion impossible** — you cannot describe a hunk's purpose and discard it without noticing you're discarding a purpose.
3. **"Tests pass" is named as a false success signal.** Tests for the surviving side always pass; the rule requires exercising the dropped side's behavior, which is where the loss would show.

## Origin

An assistant was asked to merge main into a long-lived feature branch and "resolve any conflicts." It resolved fourteen conflicts with `--ours` across the board. One of the discarded hunks was a security patch for a path traversal bug, merged to main two weeks prior. The branch shipped, the vulnerability quietly returned, and it was rediscovered by an external report a month later — a re-fix that came with a disclosure writeup.
