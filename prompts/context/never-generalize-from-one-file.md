---
title: Never Generalize From One File
slug: never-generalize-from-one-file
category: context
tags: [universal, assumptions, grounding]
works_with: all
severity: high
one_liner: "AI declaring 'this codebase uses X everywhere' after reading a single file"
---

# Never Generalize From One File

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from extrapolating one file's patterns into claims about the entire codebase.

**[Copy-paste ready version](../../install/never-generalize-from-one-file.md)** — just the instruction block, no explanation.

## The Problem

The AI reads one file, sees Redux in it, and starts narrating: "since this codebase uses Redux for state management..." The codebase is mid-migration to a different store; Redux survives in exactly four legacy files, and the AI just read one of them. From a sample of one, it has inferred a universal — and every downstream decision (where new state goes, what patterns to follow, what to recommend) now leans on a survey that never happened.

Real codebases are heterogeneous. They contain three eras of error handling, two ORMs, a folder that predates the style guide, and one module written by a contractor nobody discusses. Any single file is a biased sample — biased toward its age, its author, and its corner of the system. The AI's leap from "this file does X" to "this codebase does X" feels like synthesis but is actually the smallest possible sample size dressed up as a survey. It's especially treacherous when the user asks codebase-level questions ("how do we handle errors here?") and the AI answers from whichever file happens to be in context.

Verifying scope is cheap: a grep across the repo turns "I saw it once" into "127 matches across 40 files" or "4 matches, all in /legacy" — two very different facts.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Generalize From One File

NEVER claim "this codebase uses/does/follows X" based on observing X in one file — or even three files from the same directory. A single file is a biased sample of its era, author, and corner of the system; codebase-level claims require codebase-level evidence.

The jump from "this file does X" to "the project does X" feels like synthesis, but it's a survey with a sample size of one.

**Before making any codebase-wide claim:**
- Measure instead of extrapolating: grep the pattern across the repo and look at the count and the *distribution* — 127 matches everywhere and 4 matches confined to `/legacy` are opposite answers
- Check for competing patterns explicitly: if you found Redux, also search for Zustand/Context/MobX before declaring Redux the answer — heterogeneity is the norm, not the exception
- Scope claims to your actual evidence: "this module uses X" when you read one module; "the API layer does X" when you sampled the API layer — say "the codebase" only when you checked across it
- Mind sample bias by location and age: files in one directory share conventions that the rest of the repo may not; recently-touched files (check git log) represent current practice better than untouched ones
- When you find mixed patterns, report the mix — "mostly X, with Y in older modules" is the kind of true sentence a one-file read can never produce

**Red flags that you're about to violate this:**
- "Since this project uses X everywhere..." — after one file
- "This is clearly the established pattern here..."
- "I've seen how they do it, no need to check more files..."
- "The rest of the codebase will follow the same approach..."
- "This file is representative, surely..."
- Writing "this codebase" in a sentence supported by a single file read

---

## Why It Works

1. **It names the inferential leap.** "A survey with a sample size of one" makes the invisible jump from instance to universal visible — and slightly embarrassing, which helps.

2. **It demands distribution, not just count.** Match-count alone still misleads (4 matches could be the core or the graveyard); requiring *where* the matches live distinguishes living convention from legacy residue.

3. **It mandates the competing-pattern search.** Confirmation-only verification finds what it looked for; explicitly searching for alternatives is what actually detects migrations and mixed eras.

4. **It calibrates language to evidence.** The module/layer/codebase scoping rule gives the AI a truthful sentence at every evidence level, removing the pressure to round up to "everywhere."

## Origin

Asked where to add state for a new feature, an AI read the one open file, saw a Redux slice, and confidently scaffolded the feature as Redux — actions, reducers, selectors, the works. The team was eight months into migrating off Redux; the file on screen was on next sprint's deletion list. The new feature became the migration's final boss, the only Redux code added during the entire effort, and earned a permanent comment: "added by AI during the migration. Do not be like this code."
