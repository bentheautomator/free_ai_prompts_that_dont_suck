---
title: Don't Escalate to Sudo on Permission Errors
slug: dont-escalate-to-sudo-on-permission-errors
category: code-safety
tags: [universal, shell, files]
works_with: all
severity: critical
one_liner: "AI slapping sudo on a failing command instead of asking why it failed"
---

# Don't Escalate to Sudo on Permission Errors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating "permission denied" as an instruction to acquire more permissions.

**[Copy-paste ready version](../../install/dont-escalate-to-sudo-on-permission-errors.md)** — just the instruction block, no explanation.

## The Problem

A command fails with `EACCES`, and the AI re-runs it with `sudo`. That's the whole decision process: error mentioned permissions, sudo grants permissions, problem solved. But "permission denied" is the operating system saying *this action, from this user, on this path, was not supposed to happen* — and it's right more often than not. The pip install failing on system site-packages is telling you to use a venv. The write failing in `/usr/local` is telling you the install prefix is wrong. The delete failing on a root-owned file is telling you that file belongs to something.

Sudo doesn't fix the misunderstanding; it overrides the refusal. Now the wrong action *succeeds*: files get written into system paths owned by root (breaking future non-sudo operations in a cascade of new permission errors, each inviting more sudo), package managers corrupt their state, and — the nightmare case — the mistaken delete or overwrite that the permission system was blocking goes through at full power. An `rm` that EACCES stopped was a near-miss. `sudo rm` converts it to a hit. The AI escalates casually because sudo is just eight characters, but it's eight characters that disable the last system that was still saying no.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Escalate to Sudo on Permission Errors

NEVER respond to "permission denied" by re-running the command with sudo. A permission error is the OS refusing an action on purpose — your job is to find out why it refused, not to override the refusal.

The core problem: sudo doesn't fix what was wrong with the command; it forces the wrong command to succeed. Mistakes that permissions were blocking — wrong install target, wrong path, wrong user — execute at full power instead.

- On EACCES/permission denied, diagnose first: what path was being accessed, who owns it (`ls -l`), and *should* this operation touch that path at all? Most permission errors are wrong-target errors in disguise.
- Standard wrong-target fixes, none requiring root: pip/npm failing on system paths → virtualenv or project-local install; writes under `/usr` or `/opt` → user-local prefix (`~/.local`, `$HOME` installs); a tool's own directory unwritable → that tool was installed with sudo once before, fix its ownership story, don't deepen it.
- NEVER sudo a destructive command (rm, mv, overwrite) that failed on permissions. The refusal may be the only thing standing between a targeting mistake and data loss. Re-verify the target completely before even asking.
- If an operation legitimately needs root (system service config, package installation via the OS package manager), say so, show the exact command, and let the user run it or approve it explicitly. Sudo is the user's authority, not your convenience.
- Watch the cascade: files created under sudo are root-owned, causing the *next* permission error. If you find yourself escalating twice in one task, the approach is wrong.

**Red flags that you're about to violate this:**
- "Permission denied — let me try that with sudo..."
- "It just needs elevated privileges, no big deal..."
- "sudo pip install will get us past this..."
- "I'll sudo rm it since regular rm was blocked..."
- "Everything in this directory needs sudo anyway..."

---

## Why It Works

1. **It recasts the error as information.** "The OS is refusing on purpose" turns EACCES from an obstacle into a diagnostic — the AI's response shifts from override to investigation, which is where the real fix (wrong venv, wrong prefix, wrong path) gets found.

2. **It hard-blocks the deadliest combination.** Sudo + destructive command + permission refusal is precisely the near-miss-to-hit conversion; an absolute rule there removes all discretion at the most dangerous moment.

3. **It uses the cascade as a tripwire.** "Escalating twice means the approach is wrong" gives the AI a self-check that catches sudo-spirals early, when they're still reversible.

## Origin

Blocked by a permission error while "cleaning up an old install," an assistant re-ran its delete with sudo. The path it had computed was wrong — one level too high — and the permission system had been the only thing blocking removal of a directory shared by every service on the box. With sudo, nothing was blocking it. The restore from backups took the evening; the original cleanup target was four files.
