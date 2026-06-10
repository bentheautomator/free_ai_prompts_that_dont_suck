---
title: Never Discard Work With git checkout .
slug: never-discard-work-with-checkout-dot
category: git
tags: [universal, git, recovery]
works_with: all
severity: critical
one_liner: "Stops git checkout . and restore . from vaporizing uncommitted work"
---

# Never Discard Work With git checkout .

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "tidying" the working tree with `git checkout .` or `git restore .` and permanently destroying uncommitted changes.

**[Copy-paste ready version](../../install/never-discard-work-with-checkout-dot.md)** — just the instruction block, no explanation.

## The Problem

The AI's experiment didn't work out, or the working tree looks "messy," so it runs `git checkout .` or `git restore .` to get back to a clean state. Those commands overwrite every modified file with the last committed version, instantly and irreversibly. Uncommitted changes have no reflog, no stash entry, no trash bin. If the user had three hours of unstaged work sitting in that tree alongside the AI's experiment, it's gone, and no git command brings it back.

Assistants reach for this because "clean working tree" feels like a neutral, hygienic goal, and the command looks like an undo button. It isn't an undo; it's a delete. The critical blindspot is ownership: the working tree usually contains a mix of the AI's changes and the user's, and a path-wildcard discard makes no distinction. The AI is authorized to throw away its own failed experiment, not everything in the directory.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Discard Work With git checkout .

NEVER run `git checkout .`, `git checkout -- <path>`, `git restore .`, or `git restore <path>` to discard changes. These commands permanently destroy uncommitted work; there is no reflog, stash, or undo for what they delete.

The working tree may contain the user's uncommitted changes mixed with yours. A wildcard discard cannot tell them apart.

- To undo your own changes, prefer reversible moves: re-edit the file back, or `git stash push -m "discarding: <reason>" <paths>` so the content survives and can be recovered.
- If you must discard, discard only specific files you personally modified in this session, name them to the user first, and confirm via `git diff <file>` that nothing in the diff is unfamiliar.
- If `git status` or `git diff` shows changes you did not make, do not discard anything; report what you found and let the user decide.
- Never combine discards with other cleanup (`git clean`, `git reset --hard`) in one step; each destructive command needs its own justification.
- "Get back to a clean state" is not a goal that justifies deleting work. A dirty working tree is a normal condition, not an error.

**Red flags that you're about to violate this:**

- "My approach failed, I'll reset everything and start fresh."
- "The working tree is messy; let me clean it up first."
- "These modifications are probably all mine from earlier."
- "git checkout . is the standard way to undo local changes."
- "The user wants the bug fixed, not these half-finished edits."

---

## Why It Works

1. **It corrects a false mental model.** The AI files `checkout .` under "undo"; the rule re-files it under "permanent delete with no recovery path," which is what it actually is, and that single reframe changes the cost calculation.
2. **It makes ownership the gating question.** The honest answer to "did I make every one of these changes?" is usually "I don't know," and the rule makes that answer block the command.
3. **Routing discards through `git stash push -m`** converts an irreversible operation into a reversible one at near-zero cost, so the AI's tidiness goal is satisfied without the destruction.

## Origin

A user had spent the morning on an unfinished refactor, uncommitted, and asked their assistant to fix an unrelated failing test in the same repo. The assistant's first fix attempt didn't work, so it ran `git checkout .` to "start clean" — wiping its own attempt and the entire morning's refactor with it. Recovery options: none. The refactor was retyped from memory and an editor's local-history plugin, which saved roughly half of it.
