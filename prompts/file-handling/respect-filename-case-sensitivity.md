---
title: Respect Filename Case Sensitivity
slug: respect-filename-case-sensitivity
category: file-handling
tags: [universal, files, ci]
works_with: all
severity: high
one_liner: "Stops case-mismatched imports that work on macOS and explode on Linux CI"
---

# Respect Filename Case Sensitivity

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents imports and file references whose casing doesn't match the file on disk — invisible on macOS and Windows, fatal on Linux.

**[Copy-paste ready version](../../install/respect-filename-case-sensitivity.md)** — just the instruction block, no explanation.

## The Problem

The file is `userProfile.tsx`; the assistant writes `import UserProfile from './UserProfile'`. On the developer's Mac (case-insensitive APFS by default) this resolves fine, the dev server runs, the tests pass. On the Linux CI runner — and in the production Docker image — module resolution is case-sensitive, and the build dies with `Cannot find module './UserProfile'`. The error message is maddening because the file is *right there*, one capital letter away, and everything worked locally.

The nastier variant is renaming a file only by case (`Button.jsx` to `button.jsx`): git on a case-insensitive filesystem may not register the rename at all, leaving the repo and various checkouts disagreeing about the file's true name. Assistants cause both versions constantly because they infer casing from the symbol they're importing (components are PascalCase, so the file "must be" PascalCase too) instead of reading the actual directory listing.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Respect Filename Case Sensitivity

ALWAYS match the exact on-disk casing in every file reference: imports, requires, asset URLs, include paths, config entries. NEVER infer casing from naming conventions.

Case-insensitive filesystems (macOS and Windows defaults) forgive mismatches that case-sensitive ones (Linux, every CI runner, every container) do not. The bug is undetectable on the machine that wrote it.

- Before writing an import or path reference, verify the real name with a directory listing (`ls`), not from memory and not from the symbol's casing. `userProfile.tsx` and `UserProfile.tsx` are different files on Linux.
- When creating a file, follow the directory's existing casing convention exactly. Don't introduce `PascalCase.ts` into a `kebab-case.ts` directory or vice versa.
- Never rename a file changing only its case in a single step on macOS/Windows; git may miss it. Use `git mv File.js temp && git mv temp file.js`, or `git mv -f` where supported.
- Treat near-miss grep results as alarms: if searching for the exact path returns nothing but a case-insensitive search (`grep -ri`) hits, you have a latent Linux-only break — flag it.
- This applies beyond imports: webpack/Vite asset paths, `#include` headers, Dockerfile `COPY` sources, YAML pipeline file references, and test fixture paths all resolve case-sensitively somewhere in the pipeline.

**Red flags that you're about to violate this:**

- "The component is PascalCase, so the file must be too."
- "It resolved locally, so the path is correct."
- "I'll just rename the file to match my import instead." (Now you've made a case-only rename. See above.)
- "Case doesn't matter for filenames."
- "CI is failing on a module that obviously exists."

---

## Why It Works

1. **It attacks the verification gap directly.** The author's machine structurally cannot reveal this bug, so the rule replaces "test it" with "read the directory listing," a check that works on any filesystem.
2. **The case-only-rename procedure prevents the repo-corrupting variant**, where git history and two developers' checkouts permanently disagree about a file's name — far costlier than a failed build.
3. **Extending the rule past imports matters** because bundler asset paths and Dockerfile `COPY` lines fail at container-build time, the most expensive and confusing place to discover a one-letter casing bug.

## Origin

A green local build, a green PR preview on the author's machine, and a red production deploy: a new `import { Header } from './components/Header'` referenced a file actually named `header.tsx`. Two engineers debugged the "missing module" in the Docker build for an afternoon, because every machine they checked it on was a Mac that happily resolved the wrong casing.
