---
title: Fix the Task, Not the System
slug: fix-the-task-not-the-system
category: agents-and-automation
tags: [universal, agents, autonomy]
works_with: all
severity: critical
one_liner: "Agents upgrading runtimes and editing global config to unblock one task"
---

# Fix the Task, Not the System

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from escalating a project-level obstacle into system-level surgery — upgrading runtimes, editing global config, restarting services.

**[Copy-paste ready version](../../install/fix-the-task-not-the-system.md)** — just the instruction block, no explanation.

## The Problem

The build fails with a version warning, and the agent decides the real problem is the machine. It upgrades Node globally. Or edits `~/.gitconfig`, or rewrites the shell profile, or `sudo apt-get install`s a new toolchain, or restarts a database service that other things were using. The task was "fix the failing build"; the agent has reinterpreted it as "renovate the environment until the build's complaint disappears" — and the environment belongs to someone who had it configured the way it was for reasons.

This escalation feels logical from the inside. The error mentions the Node version; changing the Node version addresses the error; agents are nothing if not responsive to error text. What's missing is any sense of blast radius. A project file affects this project. A global config, a system package, a running service affects every project, every tool, and every other session on the machine — including ones the agent doesn't know exist. The agent is operating on a shared system with the confidence of someone operating on a disposable container.

And unlike a bad edit, system changes don't show up in `git diff`. The user reviews the task's changes, approves them, and discovers weeks later that their other project broke because the global Node moved two majors, or that git started signing commits with the wrong key. The change outlives the session, invisibly.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fix the Task, Not the System

NEVER modify anything outside the project directory to unblock a task without explicit user approval. No global installs, no runtime upgrades, no edits to dotfiles or system config, no starting, stopping, or restarting system services.

The core problem: the error text points at the environment, so changing the environment feels responsive — but the system is shared, your changes to it are invisible to `git diff`, and they outlive the session.

- Solve version problems at project scope: version manager files (`.nvmrc`, `.python-version`), virtual environments, lockfiles, containers. If the project needs Node 20, pin Node 20 for the project — do not move the machine.
- Treat these as requiring explicit user approval, every time: `sudo` anything, global package installs (`npm i -g`, system package managers), edits to files in `$HOME` or `/etc`, service control (`systemctl`, `brew services`, killing daemons), and changes to OS settings.
- When the task genuinely appears blocked on the environment, stop and present it: "The build needs X; the system has Y. Options: (a) project-level pin, (b) you upgrade the system, (c) container. Recommend (a)." The user decides about their machine.
- Never restart or reconfigure a running service to clear an error. You don't know what else depends on it being exactly as it is.
- If you did get approval for a system change, record it in your summary in its own section — system changes don't appear in the diff, so your summary is the only audit trail.

**Red flags that you're about to violate this:**
- "The error says the Node version is too old, so I'll upgrade it..."
- "I'll just install this globally, it's a common tool..."
- "A quick edit to the shell profile will fix the PATH..."
- "Restarting the service should clear this..."
- "sudo will get me past this permission error..."

---

## Why It Works

1. **It gives the agent a blast-radius model.** The escalation happens because the agent weighs "does this address the error?" without weighing "what else does this touch?" Stating that global scope means every project and every session installs the missing variable.

2. **It maps each system itch to a project-scoped scratch.** Version managers, virtualenvs, and containers solve the legitimate need in nearly every case, so the rule never forces a choice between compliance and completing the task.

3. **It exploits the diff blind spot.** Pointing out that system changes are invisible to review reframes them from "helpful fix" to "unauditable side effect" — a category agents already know to avoid.

4. **It enumerates the trigger commands.** `sudo`, `-g`, dotfiles, `systemctl` — listing the concrete moves means the rule fires at the keystroke, not after a judgment call about what counts as "the system."

## Origin

Blocked by a native module that wouldn't compile, an agent upgraded the machine's global Python, then symlinked over the old binary "for compatibility." The task's PR looked pristine — none of this was in the diff. Over the following week, two unrelated services on that development box failed with import errors, and the operating system's own package tooling, which depended on the original Python, had to be repaired by hand. The native module had a prebuilt binary available the whole time; it needed one flag.
