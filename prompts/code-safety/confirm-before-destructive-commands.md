---
title: Confirm Before Running Destructive Commands
slug: confirm-before-destructive-commands
category: code-safety
tags: [universal, foundational, essential]
works_with: all
severity: critical
one_liner: "AI running rm -rf, force-push, or DB drops without asking"
---

# Confirm Before Running Destructive Commands

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from running irreversible shell commands without explicit approval.

**[Copy-paste ready version](../../install/confirm-before-destructive-commands.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to "clean up the build artifacts" and it runs `rm -rf` on a directory that also contained uncommitted work. Or you ask it to "reset the database" and it drops tables in production because it picked the wrong connection string. Or it force-pushes to main because it thought that was the fastest way to fix a branch conflict.

AI assistants treat shell commands as just another tool. They don't distinguish between `ls` (harmless, reversible) and `git push --force origin main` (potentially catastrophic, irreversible). Without explicit rules, they'll run any command that seems to accomplish the goal — including destructive ones.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Confirm Before Running Destructive Commands

NEVER run destructive or irreversible commands without stating what you're about to do and getting explicit approval.

**Always confirm before:**
- Deleting files or directories (`rm`, `rm -rf`, `del`)
- Force-pushing (`git push --force`, `git push -f`)
- Resetting git state (`git reset --hard`, `git clean -fd`, `git checkout .`)
- Dropping or truncating database tables
- Killing processes (`kill -9`, `pkill`)
- Overwriting files without backup
- Modifying shared infrastructure (CI/CD pipelines, deployment configs, DNS)
- Any command you cannot undo

**How to confirm:**
1. State the exact command you want to run
2. Explain what it will do and what it will destroy
3. Wait for explicit "yes" or "go ahead"

**Safe alternatives to suggest first:**
- `rm` → move to a temp directory instead
- `git reset --hard` → `git stash` or `git reset --soft`
- `git push --force` → `git push --force-with-lease`
- Drop table → rename table with `_deprecated` suffix
- `kill -9` → `kill` (graceful) first

**Red flags that you're about to violate this:**
- "Let me just clean this up quickly..."
- "I'll reset this to a clean state..."
- "The fastest way to fix this is to force-push..."
- Running a command with `--force`, `--hard`, `-f`, or `rm` without pausing

---

## Why It Works

1. **Creates a speed bump at the point of maximum risk.** Destructive commands are usually the "quick fix" that causes the biggest damage. Forcing a pause at exactly that moment catches the bad decision before it executes.

2. **Makes the AI articulate consequences.** "I want to run `git reset --hard`" is easy to approve without thinking. "I want to discard all uncommitted changes in this directory, including your work-in-progress on the auth feature" makes the stakes visible.

3. **Introduces safe alternatives.** Most destructive commands have a softer version. By requiring the AI to suggest alternatives, you often get a better solution than the nuclear option it was about to run.

## Origin

An AI assistant was asked to fix a merge conflict. It decided the fastest path was `git reset --hard origin/main`, which discarded two days of uncommitted local changes. The developer hadn't pushed yet. The work was gone. A simple "I'm about to discard all local changes — proceed?" would have saved everything.
