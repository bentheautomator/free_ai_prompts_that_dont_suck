---
title: Never Delete Lockfiles to Fix Installs
slug: never-delete-lockfiles-to-fix-installs
category: dependencies
tags: [universal, dependencies, lockfiles]
works_with: all
severity: critical
one_liner: "Stops deleting package-lock.json as a fix, silently upgrading every dependency"
---

# Never Delete Lockfiles to Fix Installs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting the lockfile to make an install error go away, which silently re-resolves every dependency in the project.

**[Copy-paste ready version](../../install/never-delete-lockfiles-to-fix-installs.md)** — just the instruction block, no explanation.

## The Problem

When `npm ci` or `npm install` fails with a resolution error, AI assistants reach for the same folk remedy half the internet recommends: `rm package-lock.json && npm install`. The error disappears, the install succeeds, and the assistant reports victory. What actually happened is that every single dependency in the tree — direct and transitive — was re-resolved from scratch against whatever the registry serves today.

A lockfile is the only record of the exact versions your project was tested against. Deleting it doesn't fix the conflict; it papers over it by accepting hundreds of silent upgrades at once. The new tree may include a transitive major bump that breaks production, a package that changed behavior in a patch release, or in the worst case a freshly compromised version that the old lockfile would have pinned you away from. The diff is thousands of lines of hash churn that no human will review.

Assistants do this because it works, in the narrow sense that the command stops erroring. The error message was the obstacle, the obstacle is gone, task complete. The cost — an untested dependency tree shipped to every environment — is invisible in the terminal output.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Delete Lockfiles to Fix Installs

NEVER delete a lockfile (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock`, `Gemfile.lock`, `composer.lock`) to make an install error go away. Deleting it re-resolves every dependency in the project to new versions, which is a silent, unreviewed mass upgrade — not a fix.

- When an install fails, read the actual error. Resolution conflicts name the packages involved; fix those specific packages, not the whole tree.
- If the lockfile is genuinely corrupted or out of sync with the manifest, regenerate it with the package manager's intended command (`npm install` against the existing lockfile, `pnpm install --fix-lockfile`) and then diff the lockfile to confirm only the expected entries changed.
- If you must regenerate from scratch as a last resort, say so explicitly, explain why, and tell the user that every dependency version may have changed and the result needs full testing before merge.
- Never combine lockfile deletion with `rm -rf node_modules` as a reflex "clean slate" ritual. Clearing `node_modules` is fine; deleting the lockfile is the part that changes what gets installed.
- A lockfile-only diff with thousands of changed lines after fixing one package is a sign you did this. Stop and investigate.

**Red flags that you're about to violate this:**
- "The classic fix for this error is deleting the lockfile and reinstalling."
- "The lockfile is probably stale, regenerating it is harmless."
- "A fresh resolution will pick compatible versions automatically."
- "Stack Overflow's top answer says to remove package-lock.json."
- "It's just a lockfile, the real versions are in package.json."

---

## Why It Works

1. **It reframes the lockfile as the tested state of the project**, not an artifact that can be regenerated for free. The AI's default model is "lockfile = cache"; the instruction corrects it to "lockfile = record of what actually works."
2. **It names the folk remedy explicitly.** "Delete and reinstall" is the single most common piece of training-data advice for install errors, so the rule has to call out that exact move or the AI will follow the stronger prior.
3. **It provides the legitimate path** — targeted fixes, in-place regeneration, diff verification — so the AI isn't stuck when the lockfile really is broken.
4. **It defines the observable symptom** (a thousand-line lockfile diff for a one-package change), giving the AI a self-check it can apply after the fact.

## Origin

An assistant was asked to add a single date-picker component to a React app. The install hit a peer conflict, the assistant deleted `package-lock.json`, reinstalled, and shipped a PR where the lockfile diff was 14,000 lines. Buried in it was a transitive minor bump of a CSS tooling package that changed class-name hashing, which broke visual styling across the app in production. The date picker itself worked perfectly, which made the regression take two days to trace back to the install.
