---
title: Respect Worktrees, Don't rm Them
slug: respect-worktrees-dont-rm-them
category: git
tags: [universal, git, branches]
works_with: all
severity: medium
one_liner: "Stops worktree confusion: rm -rf removal and wrong-tree operations"
---

# Respect Worktrees, Don't rm Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating linked worktrees as disposable folders or stray clones, and from fighting git's worktree branch rules with force flags.

**[Copy-paste ready version](../../install/respect-worktrees-dont-rm-them.md)** — just the instruction block, no explanation.

## The Problem

`git worktree` lets one repository have several working directories, each on its own branch. AI assistants that haven't checked for this make two characteristic messes. First, disposal: treating a linked worktree as a stray copy of the project and deleting it with `rm -rf`. The directory dies but the repository's metadata doesn't — the branch stays registered as checked-out-elsewhere, blocking checkouts until someone discovers `git worktree prune`. Any uncommitted work in that directory dies with it, and unlike a true scratch folder, a worktree very often holds in-progress work, because that's what worktrees are *for*.

Second, fighting the rules: git refuses to check out a branch that's active in another worktree. An assistant that doesn't know why it's being refused reaches for force — `git checkout --force`, deleting the branch, or in modern git, discovering `--ignore-other-worktrees` and using it — and now two directories point at one branch with divergent states, which corrupts expectations in both. All of it stems from not asking one cheap question at the start: is this directory one of several?

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Respect Worktrees, Don't rm Them

Before branch operations or directory cleanup in any repo, check whether worktrees are in play: `git worktree list`. A linked worktree is part of the repository, not a disposable copy of it.

- NEVER delete a worktree directory with `rm -rf`. Use `git worktree remove <path>`, which refuses if the tree is dirty — that refusal is your signal that uncommitted work exists there. Inspect it before deciding anything; do not escalate to `--force` to make the refusal stop.
- If git refuses a checkout with "already checked out at <path>", that branch is live in another worktree, possibly with someone's work in progress. Do not force past it (`--ignore-other-worktrees`, branch deletion, `checkout -f`). Either work in that other directory, or create a separate branch/worktree for your task.
- Know where you are: `git rev-parse --git-common-dir` differing from `--git-dir` means you're in a linked worktree. Branch deletions, config changes, and stashes affect the whole repository, not just this directory.
- If you find orphaned worktree registrations (directory gone, entry remains in `git worktree list`), clean the metadata with `git worktree prune` — after confirming the directory is truly gone, not on an unmounted path.
- Creating a worktree is a fine, low-risk way to do side tasks (`git worktree add ../repo-hotfix hotfix-branch`) without disturbing the user's checkout; prefer it over stashing their work to switch branches.

**Red flags that you're about to violate this:**

- "There's a duplicate copy of the project here; I'll delete it."
- "Git says the branch is checked out elsewhere, but force will fix that."
- "rm -rf is equivalent to whatever git's removal command does."
- "This is the only working directory; no need to check."
- "That other worktree is old; nothing in it can matter."

---

## Why It Works

1. **One discovery command reframes the whole situation.** Every worktree failure starts with a wrong assumption ("this is the only checkout" / "this is a stray copy"); `git worktree list` costs nothing and falsifies both before any damage.
2. **It re-encodes git's refusals as information.** "Already checked out" and dirty-tree removal refusals are protective signals; naming them as such interrupts the assistant's default of treating refusals as friction to force through.
3. **Offering worktrees as the *sanctioned* tool for side tasks** channels the AI toward the feature instead of around it, which is how it learns the semantics it was missing.

## Origin

A developer kept a second worktree for an in-flight hotfix. Their assistant, doing disk cleanup, identified the directory as "a duplicate checkout of the repository" and removed it with `rm -rf`. The hotfix branch's committed work survived in the shared object store; the uncommitted half of the fix did not, and the stale worktree registration blocked checkouts of the branch until someone googled the error. The "duplicate" had been the most important directory on the disk that week.
