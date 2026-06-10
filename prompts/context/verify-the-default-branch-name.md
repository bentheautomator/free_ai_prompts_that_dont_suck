---
title: Verify the Default Branch Name
slug: verify-the-default-branch-name
category: context
tags: [universal, assumptions, verification]
works_with: all
severity: medium
one_liner: "AI hardcoding 'main' in commands and CI when the default branch is master"
---

# Verify the Default Branch Name

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from assuming the default branch is called main when this repo says otherwise.

**[Copy-paste ready version](../../install/verify-the-default-branch-name.md)** — just the instruction block, no explanation.

## The Problem

Half the AI's training data says `master`, the newer half says `main`, and plenty of real repos say `develop`, `trunk`, `release`, or something bespoke. The AI picks its favorite and types it into things: `git rebase main` in a repo with no `main`, a CI trigger on `branches: [main]` that will never fire because the default is `master`, a branch-protection suggestion for a branch that doesn't exist, diff commands comparing against the wrong base.

The loud failures are cheap — `git` says the ref doesn't exist, one round-trip lost. The quiet ones aren't. A workflow file watching the wrong branch name is valid YAML that simply never runs; deploys silently stop happening, and nobody connects it to the innocuous-looking CI edit from last week. Scripts with a hardcoded wrong base branch compute empty diffs and conclude "no changes." Gitflow-style repos add another layer: even when `main` exists, it may not be the integration branch — PRs might belong against `develop`, and the AI that targets `main` is proposing a hotfix path by accident.

The answer is sitting in `.git` and costs one command to retrieve.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify the Default Branch Name

NEVER hardcode or assume the name of this repo's default or integration branch. `main` is your statistical guess, not a fact — repos use `master`, `develop`, `trunk`, and worse, and some have a `main` that isn't where work integrates.

A wrong branch name fails loud in git commands but silently in CI triggers and scripts, where it becomes a workflow that never fires or a diff that's always empty.

**Before referencing a base/default branch:**
- Ask git: `git remote show origin` (HEAD branch line) or `git symbolic-ref refs/remotes/origin/HEAD` — or at minimum `git branch -r` to see what actually exists
- Writing CI workflows or hooks that trigger on branches: verify the name against the repo, and check existing workflow files for which branches they already reference
- In gitflow-style repos, distinguish the default branch from the integration branch — check `CONTRIBUTING.md` and recent merged PRs to see where work actually lands before targeting a PR or branching
- Computing diffs or "changed files since" lists: confirm the base ref exists and is the intended comparison point before trusting the output
- In scripts and docs meant to be portable, resolve the branch dynamically instead of hardcoding any name

**Red flags that you're about to violate this:**
- "I'll branch off main, as usual..."
- "The CI should trigger on pushes to main..."
- "Comparing against origin/main to see what changed..."
- "Every repo uses main these days..."
- "main exists, so that must be where PRs go..."
- Typing a branch name into a file or command without having seen that name in this repo's git output

---

## Why It Works

1. **It splits loud from silent failures.** The AI underweights this check because `git` usually errors helpfully. Pointing at the silent class — non-firing CI triggers, empty diffs — supplies the stakes the error message hides.

2. **It separates "default" from "integration."** The subtler half of this failure survives a branch-existence check; a repo can have `main` and still want PRs against `develop`. Making these two lookups keeps the existence check from creating false confidence.

3. **It supplies the exact command.** `git remote show origin` is faster than the assumption it replaces, eliminating the only practical reason to guess.

4. **It pushes portability toward dynamic resolution.** For scripts, no hardcoded name is ever safe across repos; resolving at runtime removes the entire failure class instead of just this instance.

## Origin

An AI updated a deployment workflow and, while in the file, "normalized" the trigger from the repo's `master` to `main`. The YAML was valid, the PR looked like a routine cleanup, and review waved it through. Deploys stopped — silently, since a workflow that never triggers also never fails. Eleven days of changes piled up undeployed until a customer asked why a fixed bug wasn't fixed. The incident review's action item was one line: "the branch is called what it's called."
