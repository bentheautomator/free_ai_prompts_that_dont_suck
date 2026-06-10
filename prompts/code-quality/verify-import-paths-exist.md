---
title: Verify Import Paths Exist
slug: verify-import-paths-exist
category: code-quality
tags: [universal, imports]
works_with: all
severity: high
one_liner: "AI importing from module paths it guessed rather than confirmed"
---

# Verify Import Paths Exist

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing imports against file paths and module structures it assumed instead of checked.

**[Copy-paste ready version](../../install/verify-import-paths-exist.md)** — just the instruction block, no explanation.

## The Problem

`import { formatDate } from '../utils/helpers'` — written into a project where the file is `src/lib/dates.ts`, the export is named `fmtDate`, and `../utils` doesn't exist from this directory anyway. AI assistants compose import paths the way they compose prose: from what a project of this shape *typically* looks like. Typical projects have `utils/helpers`. Yours has whatever it has, and the model didn't look.

Three guesses stack into one line: that the file exists at that path, that the relative depth is right (`../` vs `../../` is a coin flip the model calls confidently), and that the symbol is exported under that name and in that form (named vs default export — another coin flip). Path aliases multiply the failure surface: `@/components`, `~/lib`, `$lib` mean whatever `tsconfig.json` or the bundler says they mean, and the AI will happily use an alias convention from a different framework. The error itself is loud — `Cannot find module` — so nothing ships broken; what you lose is the round trip, repeated several times per session, plus the occasional silent case where a Python relative import resolves to the *wrong* same-named module and ships.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Import Paths Exist

NEVER write an import path you haven't verified. The file's location, the relative depth, the alias mapping, and the exported symbol name are all facts about this repository — none of them can be inferred from what projects "usually" look like.

One import line encodes three or four separate guesses, and any wrong one breaks the build or, worse, resolves to the wrong module.

**Before writing any import:**
- Confirm the target file exists at that path (list the directory or search for the filename — don't trust your mental map of the tree)
- Confirm the symbol is actually exported from it, under that exact name, and whether it's a named or default export
- Count the relative depth from the *importing* file's real location; off-by-one `../` errors are the most common failure
- Path aliases (`@/`, `~/`, `$lib`, bare `src/...`) are defined per-project in `tsconfig.json`, `vite.config`, `webpack.config`, or equivalent — verify the mapping exists here before using one, and prefer however neighboring files import the same module
- The fastest verification: find an existing import of the same module elsewhere in the codebase and copy its exact form

**Red flags that you're about to violate this:**
- "The helpers are probably in utils/..."
- "Two levels up should reach the lib directory..."
- "This project surely has the @/ alias configured..."
- "It's most likely a default export..."
- "I'll write the import and fix the path if it errors..."
- Typing a path that you have not seen in a directory listing, a search result, or another file's imports this session

---

## Why It Works

1. **It decomposes the line into its separate guesses.** The AI treats an import as one low-risk token sequence. Showing that it stacks path + depth + alias + export-form guesses recalibrates how much verification one line deserves.

2. **It kills the "fix it when it errors" workflow.** Guess-and-retry feels cheap to the model but bills the user a round trip per guess. Naming that loop as the cost makes verification the faster option, which it genuinely is.

3. **It offers the cheapest possible check.** "Copy an existing import of the same module" resolves all four guesses simultaneously with one search — making compliance easier than violation.

4. **It flags the silent variant.** Most path errors are loud, so the AI learns they're harmless. The wrong-module-same-name case (especially in Python) is the quiet one worth fearing, and naming it justifies the rule even for "harmless" guesses.

## Origin

A monorepo had two modules named `config` — one per workspace. An AI-written import guessed a relative path that resolved cleanly… to the other workspace's `config`, which exported a same-named function with defaults pointed at the staging environment. Nothing errored. The feature read staging settings in production for two weeks, intermittently and confusingly, until someone finally printed `config.__file__` in desperation and watched the wrong path come back.
