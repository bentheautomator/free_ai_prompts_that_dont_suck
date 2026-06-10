---
title: Keep Generated Artifacts Out of Commits
slug: keep-generated-artifacts-out-of-commits
category: git
tags: [universal, git]
works_with: all
severity: high
one_liner: "Stops build output and huge binaries from entering git history"
---

# Keep Generated Artifacts Out of Commits

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from committing build output, dependency directories, and large binaries that bloat the repository forever.

**[Copy-paste ready version](../../install/keep-generated-artifacts-out-of-commits.md)** — just the instruction block, no explanation.

## The Problem

The assistant runs a build as part of its task, then commits — and `dist/`, `build/`, `.next/`, a compiled binary, or a 400MB `coverage` folder rides along. Git history is append-only in practice: even after a later commit deletes the files, every clone downloads them forever. One committed `node_modules` can take a repo from 40MB to 2GB, and undoing it properly requires rewriting history, which requires coordinating every contributor.

This happens because assistants generate artifacts as a side effect of verifying their work, and those fresh files look like part of "the changes" at commit time. A missing or incomplete `.gitignore` offers no resistance. The tell is almost always visible in `git status` — dozens of new files in a directory nobody hand-edits — but only if something forces the assistant to read that output with the question "did a human write this?" in mind.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Generated Artifacts Out of Commits

NEVER commit generated files: build output, dependency directories, caches, coverage reports, compiled binaries, logs, or data dumps. Git history keeps every byte forever; a single committed artifact bloats every future clone, and removing it later requires rewriting history.

- Treat these as radioactive unless the repo demonstrably tracks them already: `node_modules/`, `dist/`, `build/`, `out/`, `target/`, `.next/`, `__pycache__/`, `*.pyc`, `coverage/`, `*.log`, `.DS_Store`, `*.sqlite`, `*.dump`, virtualenv directories.
- Before committing, scan `git status` for files no human wrote. The test: if deleting it and re-running the build recreates it, it does not belong in git.
- If a needed ignore pattern is missing, add it to `.gitignore` in the same change, scoped to the actual path (e.g. `dist/`).
- Lockfiles (`package-lock.json`, `Cargo.lock`, `poetry.lock`) are the exception: they are generated but belong in git. Follow the repo's existing convention.
- Any single file over ~5MB gets flagged to the user before staging, whatever it is. If large binaries genuinely must be versioned, that is a Git LFS conversation, not a regular `git add`.
- If you notice an artifact was already committed earlier in your session and not yet pushed, remove it from history now (`git rm -r --cached <path>` plus amend or a fixup) rather than leaving it for someone else to excavate.

**Red flags that you're about to violate this:**

- "These files appeared during my build, so they're part of my change."
- "The dist folder is small right now; it won't matter."
- "It's untracked and not ignored, so the repo must want it tracked."
- "Committing the build output will save the next person a build step."
- "I'll include the database dump so the tests are reproducible."

---

## Why It Works

1. **The regeneration test gives a crisp classifier.** "Would re-running the build recreate this?" sorts every borderline file in one step, replacing the AI's fuzzy default of "new file = my change."
2. **It corrects the gitignore inference.** Assistants read "untracked and not ignored" as a signal the repo wants the file; the rule names that as a gap in `.gitignore` to fix, not an invitation.
3. **The 5MB tripwire is mechanical**, so it works even when the AI has no idea what the file is — size alone forces the pause.

## Origin

An assistant was asked to "fix the build and commit the result." It fixed the build, then committed the result literally: the entire `dist/` directory plus a 600MB ML model checkpoint the build had downloaded. The push went through. CI clone times tripled for the whole team until someone ran a history-rewrite tool and every open branch had to be rebased onto the cleaned history.
