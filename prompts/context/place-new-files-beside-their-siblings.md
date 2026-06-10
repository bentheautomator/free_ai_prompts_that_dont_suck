---
title: Place New Files Beside Their Siblings
slug: place-new-files-beside-their-siblings
category: context
tags: [universal, conventions]
works_with: all
severity: medium
one_liner: "AI creating files in generic spots instead of where this repo keeps that kind"
---

# Place New Files Beside Their Siblings

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from putting new files where convention says they go instead of where this repo's existing files actually live.

**[Copy-paste ready version](../../install/place-new-files-beside-their-siblings.md)** — just the instruction block, no explanation.

## The Problem

A new validation helper needs a home, and the AI gives it one from the generic playbook: `src/utils/validation.ts`. This repo keeps validators in `lib/validators/`, one per domain, with an index that registers them. The new file is now a structural orphan — outside the registration pattern, invisible to the barrel export, in a directory the AI created as a side effect. Tests get the same treatment: dropped in a fresh `__tests__/` folder when every existing test sits next to its subject, or next to the subject when the repo keeps a `tests/` mirror tree.

Misplaced files cost more than tidiness. Discovery breaks — humans and tooling look where the convention points, and the orphan isn't there. Glob-driven machinery silently excludes it: test runners configured for `tests/**` never run the colocated test (which then "passes" forever), build configs miss the source file, lint coverage skips it. And each orphan weakens the convention for the next contributor, who now sees two patterns and picks one at random. Directory creation is the tell: a new directory for a common kind of file almost always means the existing home wasn't looked for.

The placement question has an empirical answer every time: where does this repo keep its other files of this kind? One search settles it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Place New Files Beside Their Siblings

ALWAYS place new files where this repo keeps existing files of the same kind — found by looking, not by convention. Before creating anything, locate its siblings; the answer to "where does this go?" is empirical, not architectural.

A misplaced file isn't just untidy: glob-configured tooling (test runners, builds, lint) silently excludes it, and discovery breaks for everyone who looks where the convention points.

**Before creating any file:**
- Find the siblings first: search for existing files of the same kind (other components, other migrations, other test files, other scripts) and put the new one with them
- Match the whole local pattern, not just the directory: naming scheme, one-per-file vs grouped, index/barrel registration, co-located test or style files that siblings carry
- Check glob-sensitive placement against config: if the test runner collects `tests/**/*.test.ts`, a colocated test will never run — verify your location is inside the patterns that matter (test config, tsconfig include, build entries)
- Treat creating a new directory as a yellow flag: for common file kinds, a new directory usually means you didn't find the existing home — search again before minting one
- Generated/special directories are off-limits for hand-placed files: don't put source in `dist/`, `build/`, `.next/`, or migration files anywhere but the migrations directory with its exact naming format
- When the repo genuinely has no precedent for this kind of file, ask or state your placement choice explicitly so it's a visible decision

**Red flags that you're about to violate this:**
- "Helpers go in utils, I'll create that folder..."
- "I'll put the test in __tests__, the usual place..."
- "Standard structure says components live here..."
- "No need to check where the other migrations are..."
- "A new directory will keep things organized..."
- Creating a file without having searched for where its siblings live

---

## Why It Works

1. **It converts placement into a lookup.** "Empirical, not architectural" removes the design question the AI loves to answer from convention, replacing it with a search whose result is the repo's own decision.

2. **It names the silent-exclusion mechanism.** Tests that never run because they're outside the collection glob are the costliest version of this failure; tying placement to tool config makes that failure checkable in advance.

3. **It flags directory creation as the tell.** New-directory-as-yellow-flag gives the AI a self-monitoring signal at exactly the moment the failure usually happens.

4. **It extends matching beyond the path.** Naming, registration, and co-located companions are part of "where files live"; matching the full local pattern prevents the right-directory-wrong-shape orphan.

## Origin

An AI added a database migration as `db/add_index.sql` — reasonable, except this project's migrations lived in `migrations/` with timestamp-prefixed names that the migration tool used for ordering. The file sat unexecuted through two deploys while the code that needed the index shipped and slowed to a crawl under load. The index "existed" — everyone had seen the migration in the diff — so the performance investigation looked everywhere else first. Total time from misplaced file to discovered cause: nine days. The migration tool's docs stating the directory requirement: one paragraph, page one.
