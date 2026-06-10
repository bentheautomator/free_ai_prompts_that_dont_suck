---
title: No Scaffolding for a Script
slug: no-scaffolding-for-a-script
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: medium
one_liner: "AI turning a one-off script into a packaged project with folders"
---

# No Scaffolding for a Script

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wrapping a one-off script in package structure, project folders, and build ceremony.

**[Copy-paste ready version](../../install/no-scaffolding-for-a-script.md)** — just the instruction block, no explanation.

## The Problem

"Write me a script that renames these files based on the CSV." A script. Singular. What materializes is a project: `src/renamer/__init__.py`, `src/renamer/core.py`, `src/renamer/cli.py`, a `pyproject.toml` with entry points, a `tests/` directory, a Makefile, and a README with installation instructions. To rename some files. Once.

The AI reaches for project scaffolding because that's what "well-structured code" looks like in repositories it learned from — but repositories are published software, and this is a disposable tool with one user and one run in its future. The scaffold inverts the tool's economics: instead of `python rename.py`, the user now needs to install a package to run it; instead of reading one file top to bottom, they navigate a tree; instead of deleting one file when done, they delete a directory structure that looks important enough that they hesitate. The ceremony also costs the AI's own effort budget, spent on `__init__.py` files instead of on edge cases in the actual renaming logic, which is the part that might eat someone's data.

A one-off script's virtues are: one file, readable top to bottom, runnable immediately, deletable without ceremony. That's not unprofessional — for this artifact, it's correct engineering.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Scaffolding for a Script

When asked for a script or one-off tool, deliver one runnable file. NEVER wrap it in package structure, project directories, or build configuration.

The core problem: scaffolding inverts a disposable tool's economics, making it slower to run, harder to read, and scarier to delete, while spending effort on ceremony instead of on the logic that actually matters.

- One file, runnable directly (`python script.py`, `node script.js`, `./script.sh`), readable top to bottom
- No `src/` trees, package init files, manifest/setup files, Makefiles, or entry-point configuration for something that will be invoked by hand
- No separate config files; inputs go in argument parsing if requested, or clearly marked constants at the top of the file if not
- No test directories for a one-off unless tests were requested; for data-touching scripts, a dry-run flag or a printed preview of planned actions is worth more and costs less
- Internal structure inside the one file (a few functions, a `main()`) is fine and good; structure across files is the thing nobody asked for
- If the user says it will be reused, shared, installed, or maintained, that changes the artifact class; confirm what they need ("Should this be a proper package?") before scaffolding

**Red flags that you're about to violate this:**
- "I'll structure this properly so it can grow into a real tool..."
- "A package layout makes this more maintainable..."
- "Best practice is to separate the CLI from the core logic..."
- "I'll add a pyproject.toml so it installs cleanly..."
- "Splitting this into modules keeps each file focused..."
- "Future you will thank me for the project structure..."

---

## Why It Works

1. **It identifies the artifact class.** The AI applies published-software norms to disposable tools; naming "one-off script" as its own class with its own virtues (immediacy, legibility, deletability) gives it the right rubric to optimize against.

2. **It redirects effort to where risk lives.** The dry-run suggestion shows what actually protects a data-touching script, making the scaffold's irrelevance to real risk visible.

3. **It permits structure at the right granularity.** Functions-within-the-file satisfies the AI's structural urge without multiplying files, closing the "but structure is good" objection.

4. **It makes reuse an explicit trigger.** The one legitimate reason to scaffold is a stated future; requiring the user to state it converts the AI's imagination of reuse into a question.

## Origin

An analyst asked for a quick script to merge two CSV exports for a one-time report. The assistant produced an installable package with six modules and a console entry point; the analyst, unable to get `pip install -e .` working in their locked-down environment, gave up and merged the files in a spreadsheet by hand. The 40 lines of actual merge logic, extracted later by a colleague into a single file, ran perfectly. The package was never installed by anyone.
