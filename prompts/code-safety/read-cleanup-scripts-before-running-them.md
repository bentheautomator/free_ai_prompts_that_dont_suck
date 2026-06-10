---
title: Read Cleanup Scripts Before Running Them
slug: read-cleanup-scripts-before-running-them
category: code-safety
tags: [universal, automation, files]
works_with: all
severity: critical
one_liner: "AI executing clean.sh or uninstall scripts without knowing what they delete"
---

# Read Cleanup Scripts Before Running Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from executing someone else's cleanup, reset, or uninstall script without first knowing exactly what it destroys.

**[Copy-paste ready version](../../install/read-cleanup-scripts-before-running-them.md)** — just the instruction block, no explanation.

## The Problem

The repo has a `scripts/clean.sh`. The task says "clean the workspace." The AI connects the two and runs it — without ever opening the file. Inside is a three-year-old script written for a different directory layout: it does `rm -rf ../output`, which used to be a build folder and is now where a sibling project keeps its source. The AI executed a delete it never read, against paths it never checked.

Assistants treat a script's filename as its documentation. `clean.sh`, `reset-env.sh`, `nuke-cache.sh`, `uninstall.sh` — the name sounds aligned with the goal, so running it feels like following project convention rather than taking a destructive action. But cleanup scripts are exactly where projects hide their most aggressive deletes, their `rm -rf` with variables, their assumptions about cwd that stopped being true two refactors ago.

The same applies to scripts the AI fetched or that a README tells it to run. "Run `./scripts/reset.sh` to start over" is an instruction written for someone who knows what the script does. The AI is not that someone.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read Cleanup Scripts Before Running Them

NEVER execute a cleanup, reset, uninstall, or teardown script without reading its full contents first. A script's filename is a marketing claim, not a contract.

The core problem: scripts named `clean.sh` or `reset-env.sh` sound safe and on-task, but they are where projects concentrate their `rm -rf` calls, their relative paths, and their stale assumptions about directory layout.

- ALWAYS read the entire script before running it — including anything it sources or invokes in turn.
- List every path the script deletes, truncates, or overwrites, and verify each one resolves where you expect from the directory you will run it in.
- Treat relative paths (`../`, `./build`, `$HOME`) and variable-built paths (`rm -rf "$OUT_DIR"`) inside scripts as unverified until you have traced what they expand to.
- If a script deletes anything outside the project directory, or anything you cannot identify, stop and ask before running it.
- Check the script's age against the repo. A cleanup script that predates a directory restructure is aimed at paths that no longer mean what it thinks.
- README instructions like "just run ./scripts/reset.sh" do not exempt you from reading it. The README author knew what it does. You don't, until you read it.

**Red flags that you're about to violate this:**
- "There's a clean script right here — that's clearly the intended way..."
- "It's a project script, the maintainers wouldn't ship something dangerous..."
- "The README says to run it, so it must be fine..."
- "It's only forty lines, what could it delete..."
- "Reading it first is overkill, the name tells me what it does..."

---

## Why It Works

1. **It breaks the filename-equals-behavior assumption.** The AI's actual reasoning is "script named clean + task says clean = run it." Stating that the name is a claim, not a contract, severs that inference.

2. **It converts execution into enumeration.** Requiring a list of every deleted path forces the AI to read the script closely enough to fail loudly when a path doesn't resolve where expected.

3. **It targets the trust transfer.** "The maintainers wrote it" and "the README says so" are borrowed authority. Naming both removes the AI's permission structure for skipping the read.

## Origin

An assistant was asked to reset a local dev environment and found `scripts/dev-reset.sh` in the repo. It ran the script directly. The script, written before a monorepo migration, contained `rm -rf ../../data` — which now pointed at a directory holding several weeks of locally collected benchmark results that existed nowhere else. Reading the eleven-line script would have taken ten seconds.
