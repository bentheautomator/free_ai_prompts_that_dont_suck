---
title: Don't Delete Temp Files That Hold State
slug: dont-delete-temp-files-that-hold-state
category: code-safety
tags: [universal, files, data]
works_with: all
severity: critical
one_liner: "AI wiping tmp and cache paths that actually store sessions, queues, or data"
---

# Don't Delete Temp Files That Hold State

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting files that look temporary but are actually live application state.

**[Copy-paste ready version](../../install/dont-delete-temp-files-that-hold-state.md)** — just the instruction block, no explanation.

## The Problem

A directory named `tmp/` is an invitation. The AI sees `tmp/`, `.cache/`, `scratch/`, files ending in `.tmp` or `.lock`, and classifies them as disposable by name alone. Then it deletes `tmp/queue.db` — the SQLite file a background worker was using as its job queue. Or it clears `.cache/sessions/` and logs out every active user of the staging server. Or it removes a `.lock` file, and the process that was relying on it for mutual exclusion happily corrupts its own data file alongside a second instance.

The naming convention lies. Plenty of real software keeps durable state in temp-flavored locations: upload staging areas mid-transfer, embedded databases, session stores, resumable download chunks, editor swap files holding unsaved work, lockfiles encoding "something is running." Whether a file is disposable is a property of who reads it next, not of what directory it sits in — and the AI can't know who reads it next without checking.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Delete Temp Files That Hold State

NEVER delete a file because its name or directory looks temporary. `tmp/`, `.cache/`, `*.tmp`, and `*.lock` are naming conventions, not guarantees — real systems keep live state in all of them.

The core problem: disposability is determined by whether anything will read the file later, and you cannot tell that from the path. Job queues live in `tmp/queue.db`. Sessions live in `.cache/`. In-progress uploads live in `tmp/staging/`.

- Before deleting anything temp-flavored, check what reads or writes it: grep the codebase for the path, check `lsof`/`fuser` for open handles, look at modification times.
- A recently modified "temp" file is a file in use. Leave it alone or ask.
- Never delete `.lock`, `.pid`, or swap files (`.swp`, `~` suffixed) to make an error go away — they encode that something is running or that unsaved work exists. Find out what, first.
- Treat embedded database files (`.db`, `.sqlite`, `.ldb`) as data regardless of where they live.
- When asked to "clean up temp files," propose the specific list of paths and get confirmation, rather than glob-deleting whole directories.
- If a process is currently running anything related to the project, assume its temp files are load-bearing until proven otherwise.

**Red flags that you're about to violate this:**
- "It's in tmp, so by definition it's safe to remove..."
- "Lock files are just leftovers from a crashed run..."
- "Clearing the cache directory can't lose anything real..."
- "These .tmp files are obviously stale..."
- "I'll wipe the whole scratch folder to be thorough..."

---

## Why It Works

1. **It reframes disposability.** The AI classifies files by path semantics; the rule replaces that with "disposable = nothing reads it later," which is checkable, and gives the concrete checks (grep, lsof, mtime).

2. **It protects the highest-value targets by name.** Lockfiles, pidfiles, and embedded databases are the cases where the convention lies most expensively. Enumerating them removes the need for judgment exactly where judgment fails.

3. **It swaps glob-deletes for proposed lists.** Listing specific paths before deleting means the one file that matters gets seen by a human before it's gone.

## Origin

A developer asked an assistant to free up space in a project directory. It deleted `tmp/` wholesale, which included `tmp/jobs.sqlite` — the queue backing a worker that was halfway through a nightly import. The import didn't fail; it simply never resumed, and the missing records weren't noticed until the following week. The directory name did all the convincing.
