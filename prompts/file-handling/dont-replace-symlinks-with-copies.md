---
title: Don't Replace Symlinks with Copies
slug: dont-replace-symlinks-with-copies
category: file-handling
tags: [universal, files, unix]
works_with: all
severity: medium
one_liner: "Stops edits from turning a symlink into a stale fork of its target"
---

# Don't Replace Symlinks with Copies

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents writes through a symlink from destroying the link and leaving behind a regular-file copy that silently diverges from its target.

**[Copy-paste ready version](../../install/dont-replace-symlinks-with-copies.md)** — just the instruction block, no explanation.

## The Problem

A repo links `config/current.yaml -> environments/prod.yaml` so one file has one source of truth. An AI assistant opens `config/current.yaml`, edits it, and writes the result back as a new regular file — many write paths (write-temp-then-rename, delete-then-create, some editor backends) replace the link itself rather than writing through it. The repo now contains two files that were one. Edits to either no longer reach the other, and the divergence is invisible until prod and the "current" config disagree about something important.

Symlinks encode intent: dotfile managers, monorepo tool shims, `node_modules/.bin`, versioned deploy layouts (`current -> releases/2024-06-01`), and shared config all rely on link-ness, not just content. Git stores symlinks as a distinct object type, so the replacement shows up as a confusing typechange in the diff — if anyone reads the diff metadata, which content-focused review rarely does. Assistants break links because their tools dereference transparently on read, so a symlink looks exactly like its target right up until write time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Replace Symlinks with Copies

NEVER turn a symlink into a regular file as a side effect of editing. If a path is a link, decide deliberately: edit the target through the link, or edit the target directly — but the link must still be a link afterward.

A symlink replaced by a copy creates a silent fork: two files where the project depends on there being one.

- Before editing, check what you're touching: `ls -l <path>` (look for `->`) or `test -L <path>`. Reads dereference transparently, so content alone won't tell you.
- If it's a link, the real question is "should this change apply to the target?" Usually yes: edit the target file at its real path (`readlink -f`). The link stays untouched.
- Avoid write strategies that replace the path: delete-and-recreate and rename-over-the-top both destroy the link. In-place writes through the link preserve it.
- When copying or moving trees that may contain links, preserve them: `cp -a`/`cp -P` not bare `cp -r` semantics that follow links; `rsync -a` not `rsync -rL`; `tar` defaults are safe, `--dereference` is not.
- After your edit, `git status` showing `typechange` on a path you edited means you broke a link. Restore it (`ln -sfn <target> <path>`) before finishing.
- If the task genuinely requires materializing a link into a real file, say so explicitly; it changes the repo's structure, not just its content.

**Red flags that you're about to violate this:**

- "It opens and reads like a normal file, so it is one."
- "I'll recreate the file with the new content." (You'll recreate it as the wrong kind of file.)
- "The diff shows my content change, looks good." (Check for the typechange line.)
- "Copying the target here makes things simpler."
- "Symlinks are an infrastructure detail, not my problem."

---

## Why It Works

1. **It names the read/write asymmetry that causes the bug:** reads dereference, many writes replace. An assistant that knows the trap is in the write path checks `ls -l` before choosing a write strategy.
2. **The `typechange` line in `git status` is a mechanical detector** for an otherwise invisible structural change — one word in command output versus a divergence discovered weeks later in production config.
3. **It covers the copy/sync flag traps (`cp -r`, `rsync -L`, `tar --dereference`)** because tree operations are where links get flattened in bulk, ten at a time, with no diff to catch it.

## Origin

A deploy layout used `current -> releases/<timestamp>`. An assistant asked to hotfix a template edited `current/app.conf` via a delete-and-rewrite, which materialized `current` as a real directory on the deploy host. The next release script happily wrote a new release directory and repointed... nothing, because `current` was no longer a link. The host served the hotfixed-but-ancient release for two days before monitoring drift exposed it.
