---
title: No git reset --hard Without a Safety Net
slug: no-reset-hard-without-safety-net
category: git
tags: [universal, git, recovery]
works_with: all
severity: critical
one_liner: "Stops reset --hard from destroying uncommitted work with no recovery"
---

# No git reset --hard Without a Safety Net

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from using `git reset --hard` as a general-purpose fix and obliterating uncommitted changes in the process.

**[Copy-paste ready version](../../install/no-reset-hard-without-safety-net.md)** — just the instruction block, no explanation.

## The Problem

`git reset --hard` is the AI assistant's favorite escape hatch. Branch in a weird state? Reset hard. Merge looking complicated? Reset hard. Want to "match the remote"? `git reset --hard origin/main`. The command does two unrelated things at once — moves the branch pointer *and* overwrites the working tree and index — and it's the second half that kills: every uncommitted change in the repository is destroyed instantly. Committed work survives in the reflog; uncommitted and staged-but-uncommitted work does not survive anywhere.

Assistants over-use it because it reliably produces a "clean" state from any confusion, and confusion is exactly when they reach for the biggest hammer available. The command's name doesn't say "delete," its output is a single calm line, and nothing about it hints that it may have just erased a day of the user's unstaged work that happened to be sitting in the same tree.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No git reset --hard Without a Safety Net

NEVER run `git reset --hard` while the working tree or index contains changes you have not preserved. The command destroys all uncommitted work instantly; the reflog protects commits, not your working tree.

- Before any `reset --hard`, run `git status`. If it shows anything besides a clean tree, preserve first: `git stash push -u -m "pre-reset safety net"` (the `-u` captures untracked files too). Only then reset.
- Ask whether you need `--hard` at all. To unstage, use `git reset` (mixed) or `git restore --staged`. To move a branch pointer without touching files, use `git reset --soft` or `git branch -f`. `--hard` is for the rare case where discarding the tree is the explicit goal.
- Never use `reset --hard` to "sync with the remote" or "fix" a confusing state. Diagnose first: `git status`, `git log --oneline --graph -10`, `git stash list`. Confusion is a reason to gather information, not to erase it.
- Never run it on a branch you haven't confirmed you're on: `git branch --show-current` first.
- If you preserved a safety-net stash and the reset went fine, tell the user the stash exists rather than silently dropping it.

**Red flags that you're about to violate this:**

- "The state is confusing; a hard reset gives me a known-good baseline."
- "git status shows some changes but they're probably not important."
- "I'll reset --hard to origin to make sure we're in sync."
- "The reflog means nothing is ever really lost."
- "This is the fastest way to undo my last few steps."

---

## Why It Works

1. **It explodes the reflog myth.** Assistants genuinely believe reset is safe because "the reflog has everything"; the rule states the precise boundary — commits yes, working tree no — which is the fact that changes the decision.
2. **The mandatory pre-reset stash makes the destructive path the longer path.** When safety costs one command, "I'm in a hurry" stops selecting for data loss.
3. **It breaks the confusion-to-hammer reflex** by prescribing diagnosis commands for exactly the moment the AI would otherwise escalate, turning "I don't understand this state" into reading instead of erasing.

## Origin

An assistant got tangled while reordering commits, decided to start over, and ran `git reset --hard origin/feature` for a clean slate. The working tree at that moment held the user's uncommitted schema migration — four hours of careful constraint work that had never been staged. The reflog dutifully contained every commit and none of the migration. The constraint logic was reconstructed the next day from a terminal scrollback screenshot.
