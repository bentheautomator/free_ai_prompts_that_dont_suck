---
title: Treat Data Directories as Data, Not Artifacts
slug: treat-data-directories-as-data
category: code-safety
tags: [universal, files, data]
works_with: all
severity: critical
one_liner: "AI wiping uploads and storage folders as if they were build output"
---

# Treat Data Directories as Data, Not Artifacts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting directories of accumulated data on the theory that they're regenerable output.

**[Copy-paste ready version](../../install/treat-data-directories-as-data.md)** — just the instruction block, no explanation.

## The Problem

A project tree contains two kinds of directories the repo doesn't track: things the build *produces* (`dist/`, `build/`, `.next/`) and things the application *accumulates* (`uploads/`, `storage/`, `data/`, `recordings/`, `exports/`). Both are gitignored. Both are absent from fresh clones. Both look identical to an AI deciding what's safe to delete during a cleanup, a disk-space hunt, or a "reset the app" task. Only one of them comes back when you rebuild.

The distinction the AI misses is *provenance*: build artifacts are derived from source and regenerate on demand; accumulated data arrived from the outside world — users uploaded it, jobs computed it over weeks, integrations deposited it — and exists nowhere else. `rm -rf uploads/` doesn't cost a rebuild; it costs every file every user ever submitted to the local or staging instance, and sometimes (when someone ran "the simple deployment" with local storage) to production. Gitignore status, which the AI uses as its disposability signal, is actively misleading here: data directories are ignored *because they're too valuable and too large to commit*, not because they're worthless.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Treat Data Directories as Data, Not Artifacts

NEVER delete a directory as "generated output" unless you've verified the project can regenerate it from source. Directories like `uploads/`, `storage/`, `data/`, `media/`, `exports/`, and `recordings/` are accumulated data — they arrived from users, jobs, and integrations, and no rebuild brings them back.

The core problem: build artifacts and accumulated data look identical (both gitignored, both absent from fresh clones), but only artifacts are regenerable. Gitignore status signals "don't commit," not "safe to delete."

- Before deleting any untracked directory, answer: what *writes* to it? If the writer is the build system or a compiler, it's an artifact. If the writer is the running application, a user, a scheduled job, or an external system, it's data. When you can't determine the writer, treat it as data.
- Check the evidence: grep the codebase for the directory name (upload handlers, storage config, job output paths point at data), look at file types and timestamps inside (user-named PDFs accumulated over months are not build output).
- Hard list, never delete without explicit user instruction naming the directory: `uploads/`, `storage/`, `data/`, `media/`, `files/`, `exports/`, `backups/`, `recordings/`, anything containing `.sqlite`/`.db` files.
- "Reset the app" means reset *state you were asked to reset* — it does not silently include wiping accumulated user data. Enumerate what a reset will delete and confirm.
- When cleaning disk space, report sizes per directory with your artifact-vs-data classification, and delete only from the artifact column after confirmation.

**Red flags that you're about to violate this:**
- "It's gitignored, so it's generated stuff..."
- "It's not in the repo, so the app must recreate it..."
- "The storage folder is huge — clearing it frees the most space..."
- "A clean reset should include emptying the data directory..."
- "It's only staging, the uploads there don't matter..."

---

## Why It Works

1. **It replaces the gitignore heuristic with the writer test.** "Who writes to it?" is answerable from the codebase and cleanly separates compiler output from accumulated data — exactly the boundary the AI's current signal (tracked vs. untracked) fails to draw.

2. **It defaults the ambiguous case to data.** When the writer can't be determined, the rule chooses the recoverable error (didn't delete an artifact) over the unrecoverable one (deleted the uploads).

3. **It names the directories.** A hard list of protected names catches the failure even when the AI skips the reasoning — `uploads/` simply doesn't get deleted on autopilot anymore.

## Origin

Freeing disk space on a staging server, an assistant identified the largest directory — `storage/app/` at 60 GB — as "application cache and generated files" and deleted it. It was the upload store for a document-review tool: every file submitted during four months of customer pilots. Staging was the only environment those pilots had ever touched. The build directory it should have deleted was 800 MB and two entries lower in the size listing.
