---
title: Detect the Default Branch, Don't Guess
slug: detect-the-default-branch-dont-guess
category: git
tags: [universal, git, branches]
works_with: all
severity: medium
one_liner: "Stops hardcoded 'main' or 'master' assumptions from hitting wrong branches"
---

# Detect the Default Branch, Don't Guess

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from assuming the default branch is named `main` (or `master`) and aiming merges, diffs, and branches at the wrong target.

**[Copy-paste ready version](../../install/detect-the-default-branch-dont-guess.md)** — just the instruction block, no explanation.

## The Problem

Half the repos in the world call their default branch `main`, a large chunk still say `master`, and plenty use `develop`, `trunk`, or something house-specific — often with `main` *also* existing as a stale or protected artifact. AI assistants hardcode their guess. The damage shows up everywhere downstream: branching off an eighteen-month-old `master` and "fixing" bugs that were fixed last year, diffing a PR against the wrong base so the diff includes hundreds of unrelated commits, merging upstream's stale branch into feature work, or telling the user their change "is already on main" when the repo integrates through `develop`.

What makes this failure stubborn is that the wrong guess often *works mechanically* — `master` exists, the checkout succeeds, the diff renders — so nothing errors. The work is just built on the wrong foundation, and that's discovered at review time or merge time, when the cost of redoing it is maximal. Detection costs one command, and the answer doesn't change mid-session, so there is exactly no excuse.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Detect the Default Branch, Don't Guess

Never assume the default branch is named `main` or `master`. Detect it once per repo before any operation that references a base branch — branching, diffing, merging, rebasing, or describing where changes will land.

- Detect with: `git symbolic-ref refs/remotes/origin/HEAD --short` (gives e.g. `origin/main`). If unset, `git remote show origin` and read the "HEAD branch" line; it can be cached locally afterward with `git remote set-head origin --auto`.
- Mere existence of a branch named `main` or `master` proves nothing. Repos often carry both, one of them stale by months. Existence is not defaultness.
- Use the detected name everywhere a base appears: `git checkout -b feature/x origin/<default>`, `git diff origin/<default>...HEAD`, merge targets, and in your prose to the user ("this will merge into `develop`").
- Some teams integrate through a branch that is NOT the repo's HEAD branch (e.g. PRs target `develop` while `main` tracks releases). If both patterns are plausible, look for evidence — recent merge commits (`git log --oneline --merges -10 <branch>`), contributing docs — or ask, rather than picking the famous name.
- If you catch yourself typing a base branch name you have not verified in this repo, that line is wrong until proven otherwise.

**Red flags that you're about to violate this:**

- "It's main; it's always main these days."
- "master exists in this repo, so that's the one."
- "Checking the default branch is overhead for a simple diff."
- "The last repo I worked in used develop, so this one probably does too."
- "The checkout succeeded, so I picked the right base."

---

## Why It Works

1. **It attacks the confirmation trap directly.** "The branch exists and the command succeeded" is the evidence the AI uses to validate its guess; stating that existence proves nothing removes the false confirmation that lets wrong guesses survive.
2. **Detection is made cheaper than guessing.** One command with a cacheable answer, specified exactly, means the safe behavior has no cost advantage to overcome — rules that ask for effort lose; this one asks for ten characters of attention.
3. **The integration-branch caveat covers the second-order version** of the failure (right HEAD branch, wrong PR target), which is where assistants that learned the first lesson still faceplant.

## Origin

A repo had migrated from `master` to `main` a year earlier, keeping `master` frozen for old links. An assistant, asked for a hotfix, branched from `master` without checking, fixed the bug, and the diff looked clean — against a base twelve months stale. The PR showed four hundred phantom changes, the actual fix was invisible inside them, and the work was redone from the right base after a reviewer spent twenty minutes figuring out why the assistant had apparently rewritten half the product.
