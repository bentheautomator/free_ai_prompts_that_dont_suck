---
title: No Drive-By File Moves
slug: no-drive-by-file-moves
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI renaming and relocating files as a side effect of editing them"
---

# No Drive-By File Moves

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming files or reorganizing directories while it was only supposed to edit contents.

**[Copy-paste ready version](../../install/no-drive-by-file-moves.md)** — just the instruction block, no explanation.

## The Problem

The task was to fix a function in `utils.py`. The delivery: the fix — in `string_utils.py`, because the AI split `utils.py` into three "better organized" modules, updated fourteen imports, and left `utils.py` deleted. Or smaller-scale: it renamed `helpers.js` to `dom-helpers.js` "to reflect what it actually does," touching every importer. The content change you asked for is in there somewhere, distributed across a reorganization you didn't.

File paths are load-bearing far beyond the import graph the AI can see and fix. Build configs, deployment scripts, documentation links, code owners files, lazy/dynamic imports built from strings, test collection patterns, and other people's muscle memory all reference paths — and a move silently breaks any of them the AI didn't find. Version control suffers too: rename plus heavy edit in one commit frequently defeats rename detection, so the file's history flatlines and `git log --follow` dead-ends right where someone will one day need it. And every open branch touching the old path is now a conflict festival.

Reorganizing a module layout is sometimes worth all of this. That calculation belongs to the team, made deliberately, in a diff that contains nothing else.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Drive-By File Moves

Edit files where they live. NEVER rename, move, split, or merge files as a side effect of changing their contents.

The core problem: paths are referenced by build configs, deploy scripts, dynamic imports, docs, and open branches you can't see, and a move bundled with edits also defeats version-control rename detection, severing the file's history.

- The file you were asked to change keeps its name, its location, and its boundaries
- Do not split a "too big" file into modules, merge "too small" ones, or hoist code into new files while performing content changes
- Do not rename files to better describe their contents, match naming conventions, or fix inconsistent casing in passing (casing renames are extra treacherous across case-insensitive filesystems)
- Do not relocate files into "more logical" directories or restructure folders as part of a task that didn't ask for it
- New files for genuinely new components the task requires are fine; this rule is about not moving what exists
- If a move was requested, make it a move-only commit where possible, with content changes separate, so history survives and the diff is verifiable
- Think the layout needs reorganizing? Propose it in a sentence or two and let the team schedule it; they know which branches are open and what references the paths

**Red flags that you're about to violate this:**
- "This filename doesn't describe the contents anymore, I'll rename it..."
- "While editing, I'll split this huge file into logical modules..."
- "This file clearly belongs in the services directory..."
- "I'll fix the inconsistent file naming as I go..."
- "Moving this is safe, I updated all the imports I found..."

---

## Why It Works

1. **It enumerates the invisible reference holders.** The AI verifies moves against the import graph it can grep; listing build configs, deploy scripts, string-built imports, and open branches shows the graph it's checking is the minority of the references.

2. **It surfaces the history cost.** Rename-plus-edit defeating rename detection is a mechanism the AI doesn't model; once named, "I updated all the imports" stops sounding like the whole job.

3. **It separates move-only from edit commits.** For requested moves, the procedural rule (move commits contain only moves) preserves both history and reviewability, giving the legitimate case a safe shape.

4. **It assigns the scheduling to those with visibility.** Open branches and path references are exactly what the team knows and the AI doesn't; routing reorganization proposals to them matches the decision to the information.

## Origin

Asked to fix one parser bug, an assistant also reorganized the parsers into a new directory tree, updating every static import correctly. It missed a deployment script that referenced one parser by path and a plugin loader that built import strings at runtime. Staging caught the deploy script; production caught the plugin loader, at month-end, when the one report that used that plugin failed to generate. Three systems broke for a reorganization nobody had requested, wrapped around a bug fix that was four lines.
