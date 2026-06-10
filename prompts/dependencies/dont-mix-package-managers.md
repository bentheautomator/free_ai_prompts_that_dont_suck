---
title: Don't Mix Package Managers
slug: dont-mix-package-managers
category: dependencies
tags: [universal, dependencies, lockfiles]
works_with: all
severity: high
one_liner: "Stops running npm in a pnpm repo and committing a second, conflicting lockfile"
---

# Don't Mix Package Managers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from introducing a second package manager into a project that already has one, leaving dueling lockfiles behind.

**[Copy-paste ready version](../../install/dont-mix-package-managers.md)** — just the instruction block, no explanation.

## The Problem

A repo managed with pnpm has `pnpm-lock.yaml` sitting in its root, and the assistant runs `npm install axios` anyway — because npm is the default muscle memory of the training data. Now the repo has two lockfiles. `pnpm-lock.yaml` doesn't know about axios; the brand-new `package-lock.json` only knows about this one install. Depending on which lockfile CI reads, the build either misses the new dependency or resolves the whole tree differently than every developer's machine.

The damage compounds quietly. Yarn and npm hoist differently than pnpm, so code that accidentally depends on hoisting will work under the wrong manager and fail under the right one. Helpful teammates see the install error, run their own preferred manager, and a third lockfile appears. Each lockfile claims to be the truth, and none of them agree.

This is a context failure, not a knowledge failure. The assistant knows pnpm exists; it just doesn't check which manager this repo uses before typing the command it types most often. The evidence is one `ls` away: the lockfile name, the `packageManager` field in package.json, the `engines` block, the CI config.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Mix Package Managers

ALWAYS detect which package manager a project uses before running any install, add, remove, or script command — and use only that one. Introducing a second manager creates a second lockfile, and two lockfiles means two conflicting versions of the truth.

- Detect before acting: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm, `bun.lockb`/`bun.lock` → bun. The `packageManager` field in package.json is authoritative when present. The same applies outside JS: `poetry.lock` → poetry, `uv.lock` → uv, `Pipfile.lock` → pipenv.
- Use the detected manager for everything: installs (`pnpm add`, not `npm install`), script running (`yarn test`, not `npm test`), and exec (`pnpm dlx`, not `npx`). Script runners differ in how they resolve binaries and lifecycle hooks.
- If you accidentally generate a foreign lockfile (a stray `package-lock.json` in a pnpm repo), delete that foreign lockfile before committing. Never commit two lockfiles.
- Never "switch" a repo's package manager as a side effect of a task. Migrating managers is a deliberate project decision with its own PR.
- If no lockfile and no `packageManager` field exists, ask which manager the team uses rather than defaulting to npm.

**Red flags that you're about to violate this:**
- "npm install is the standard way to add a package."
- "The command failed under pnpm, so I'll try it with npm."
- "A package-lock.json appeared, but extra lockfiles are harmless."
- "yarn and npm are interchangeable for a simple install."
- "I'll use npx for this even though the repo uses pnpm."

---

## Why It Works

1. **It inserts a detection step before the most habitual command the AI runs.** `npm install` is a reflex from training data; an explicit pre-check is the only thing that reliably interrupts a reflex.
2. **It gives a mechanical detection table** — lockfile name to manager — so the check costs one directory listing, leaving no efficiency excuse.
3. **It covers the cleanup case.** Assistants that slip don't know a foreign lockfile is damage; telling them to delete it before committing contains the blast radius.
4. **It closes the fallback loophole** ("pnpm failed, try npm"), which is how most second lockfiles are actually born — not ignorance, but error-recovery improvisation.

## Origin

In a pnpm monorepo, an assistant added a testing utility with `npm install`, committing both the new `package-lock.json` and code that imported the package. CI used `pnpm install --frozen-lockfile`, which knew nothing about the new dependency and failed — so a teammate's assistant "fixed" CI by switching the workflow to `npm ci`. The workspace packages, which npm couldn't resolve the same way, broke one by one over the next three days until someone diffed the two lockfiles and unwound both commits.
