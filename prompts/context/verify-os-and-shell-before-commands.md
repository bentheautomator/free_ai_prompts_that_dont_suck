---
title: Verify OS and Shell Before Giving Commands
slug: verify-os-and-shell-before-commands
category: context
tags: [universal, environment, assumptions]
works_with: all
severity: high
one_liner: "AI giving bash-isms and apt-get to a user on Windows PowerShell"
---

# Verify OS and Shell Before Giving Commands

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from assuming everyone runs Linux with bash when the user is on Windows, macOS, or fish.

**[Copy-paste ready version](../../install/verify-os-and-shell-before-commands.md)** — just the instruction block, no explanation.

## The Problem

The AI's imagined user runs Ubuntu with bash. So out come `apt-get install`, `export VAR=value`, `rm -rf ./build`, forward slashes, `&&` chains, and `~/.bashrc` edits — delivered to a developer on Windows whose terminal is PowerShell, where half of those commands fail and the other half do something different. `export` isn't a thing. `&&` only works in recent PowerShell versions. Paths use backslashes and a different root. There is no `~/.bashrc` to edit.

macOS users get their own flavor: BSD `sed -i` needs an argument GNU `sed` doesn't, `apt` doesn't exist, and Homebrew package names differ from apt package names. Fish users watch `export FOO=bar` fail in a shell that wants `set -x FOO bar`. Each wrong command costs a round-trip — or worse, partially executes. A path-manipulation command written for one OS and run on another is how "clean the build directory" becomes "delete the wrong directory."

The environment is rarely a secret. The session often states the platform outright; failing that, the filesystem is full of tells. The failure is defaulting instead of looking.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify OS and Shell Before Giving Commands

NEVER write commands for an assumed operating system or shell. Confirm the actual platform first — Linux-with-bash is your training-data default, not a fact about this user.

A wrong-platform command costs a failed round-trip at best; a path or deletion command with different semantics on the user's OS can destroy the wrong thing.

**Before giving or running shell commands:**
- Check the environment info your session provides (platform, OS version, shell) — most coding tools state it explicitly
- No environment info? Look for tells: `C:\` paths or `.ps1` scripts mean Windows; `brew` references or `/Users/` paths mean macOS; `/home/` suggests Linux — or just ask
- Match the shell, not just the OS: `export` (bash/zsh) vs `set -x` (fish) vs `$env:` (PowerShell); `&&` chaining is not universal
- Use the platform's package manager: apt/dnf/pacman on Linux, brew on macOS, winget/choco/scoop on Windows — never prescribe `apt-get` cross-platform
- Mind command divergence: BSD vs GNU `sed`/`grep` flags, `rm -rf` vs `Remove-Item -Recurse`, path separators and case-sensitivity
- When writing scripts for the repo (not the user's terminal), match what the repo already contains — a repo full of `.sh` files implies its own target environment

**Red flags that you're about to violate this:**
- "They're a developer, they're probably on Linux or at least WSL..."
- "These commands are basically portable..."
- "I'll write it for bash and they can translate..."
- "sed -i works the same everywhere..."
- "Everyone has grep, curl, and make installed..."
- Writing `apt-get` without having seen a single piece of evidence about the platform

---

## Why It Works

1. **It reclassifies the default as a guess.** The AI experiences "user is on Linux" as background truth, not as an assumption it made. Labeling it explicitly turns an invisible prior into a checkable claim.

2. **It separates OS from shell.** Plenty of failures survive an OS check — macOS-with-fish, Windows-with-git-bash. Treating the shell as its own variable catches the second layer.

3. **It points at evidence that already exists.** Session environment blocks, path styles, script extensions — the answer is usually one observation away, which makes "I had to guess" indefensible.

4. **It flags destructive commands as the high-stakes case.** Cross-platform path semantics turn cleanup commands into hazards; calling this out raises the verification bar exactly where it matters.

## Origin

A developer on Windows asked how to clear a corrupted local cache. The AI supplied a bash one-liner with `rm -rf` and a forward-slash path with a `$HOME` variable. Run in PowerShell, the variable didn't expand the way the AI assumed and the command flagged errors — so the AI "fixed" it by switching to a `Remove-Item` invocation it constructed from the same wrong path logic, which deleted a sibling directory containing uncommitted work. The cache, ironically, survived.
