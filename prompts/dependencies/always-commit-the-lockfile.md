---
title: Always Commit the Lockfile
slug: always-commit-the-lockfile
category: dependencies
tags: [universal, dependencies, lockfiles]
works_with: all
severity: high
one_liner: "Stops gitignoring lockfiles or leaving lockfile changes out of the commit"
---

# Always Commit the Lockfile

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from gitignoring the lockfile or committing a dependency change without it.

**[Copy-paste ready version](../../install/always-commit-the-lockfile.md)** — just the instruction block, no explanation.

## The Problem

There are two versions of this failure and AI assistants commit both. The first: while writing a `.gitignore` for a new project, the assistant adds `package-lock.json` or `poetry.lock` to it — a habit inherited from old blog posts, library-authoring advice misapplied to applications, and a general instinct that generated files don't belong in git. The second: the assistant installs a package, then commits only the files it thinks of as "its changes" — source code and package.json — leaving the modified lockfile sitting in the working tree.

Either way, the outcome is a project where the manifest and the lockfile tell different stories. Teammates install and get versions the author never ran. CI's `npm ci` fails with "lockfile out of sync" on a commit whose author swears it worked. The reproducibility the lockfile exists to provide is gone, and it degrades silently — everything works on the machine where the desync was created.

The gitignore variant comes from stale training data: "don't commit lockfiles" was real advice, for libraries, a long time ago. The partial-commit variant comes from the assistant's narrow definition of its diff — the lockfile changed as a side effect of a command rather than an edit, so it doesn't register as part of the work.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Always Commit the Lockfile

ALWAYS commit the lockfile, and ALWAYS commit it in the same commit as the dependency change that modified it. The lockfile is the reproducible half of every dependency change; a commit that adds a package without it is half a commit.

- Never add lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, `Gemfile.lock`, `composer.lock`) to `.gitignore`. The old "libraries shouldn't commit lockfiles" advice does not apply to applications, and modern guidance commits them even for libraries' own CI.
- After any install/add/remove/update command, run `git status` and confirm the lockfile change is staged alongside the manifest change. A diff touching package.json but not the lockfile is incomplete — stop and include it.
- If you find a lockfile already gitignored in an application repo, flag it to the user as a reproducibility problem. Don't silently un-ignore it, but don't pretend it's fine either.
- Never commit a lockfile change with no corresponding manifest or code change either, unless the task is explicitly a dependency refresh — an orphan lockfile diff means some command mutated state you didn't intend to ship.
- Generated-files instincts don't apply here: the lockfile is generated, and it is also the single most important file for making installs reproducible. Both things are true.

**Red flags that you're about to violate this:**
- "Lockfiles are generated, and generated files go in .gitignore."
- "I'll commit my code changes; the lockfile churn isn't part of my work."
- "The lockfile diff is huge and noisy, better to leave it out."
- "package.json has the version, so the lockfile is redundant."
- "I'll let whoever installs next regenerate it themselves."

---

## Why It Works

1. **It corrects a stale prior by acknowledging it.** The AI learned "don't commit lockfiles" from somewhere real; naming that advice as outdated-and-library-specific defuses it better than contradiction alone.
2. **It redefines the unit of work.** "Manifest change + lockfile change = one commit" turns the lockfile from incidental side effect into a required component the AI checks for.
3. **It adds a `git status` verification step**, catching the common case where the lockfile changed but never entered the AI's concept of its own diff.
4. **It blocks both directions** — missing lockfile and orphan lockfile — so the AI can't satisfy the rule by committing unrelated lockfile churn.

## Origin

An assistant scaffolding a new service wrote a thorough `.gitignore` that included `package-lock.json`, copied from a years-old template in its training data. The team of five worked on the service for a month, each developer resolving dependencies independently, until a bug appeared that only two of them could reproduce. They were on different minor versions of the same ORM — and had no lockfile to prove it, which is why the comparison took two days instead of two minutes.
