---
title: Don't Sync With a Bare git pull
slug: dont-sync-with-a-bare-git-pull
category: git
tags: [universal, git]
works_with: all
severity: medium
one_liner: "Stops blind git pull from creating surprise merges and conflicts"
---

# Don't Sync With a Bare git pull

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running `git pull` as a reflex and getting surprise merge commits, mid-task conflicts, or merges into a dirty working tree.

**[Copy-paste ready version](../../install/dont-sync-with-a-bare-git-pull.md)** — just the instruction block, no explanation.

## The Problem

`git pull` is two operations wearing one trench coat: a fetch, then an immediate merge (or rebase, depending on config the AI never checked) into whatever state the working tree happens to be in. AI assistants run it as a reflexive "make sure we're up to date" before starting work — and when the branches have diverged, the reflex creates a merge commit titled `Merge branch 'main' of ...` that nobody asked for, or drops the assistant into conflict resolution before it has done anything else. With uncommitted changes present, the pull can refuse, or worse, interleave the merge with the user's half-finished work.

The deeper issue is that pull acts before it informs. The assistant has no idea what's incoming — three commits or three hundred, a teammate's WIP or a rewritten branch — because pulling skips the step where you look. `git fetch` gets the same information with zero side effects, and after looking, the right integration (fast-forward, merge, rebase, or nothing at all) is usually obvious.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Sync With a Bare git pull

Do not run `git pull` as a reflex. Fetch first, look at what's incoming, then integrate deliberately — or don't.

`git pull` is fetch plus an immediate merge or rebase (whichever the local config says) into the current tree. Run blind, it creates surprise merge commits, starts conflicts you didn't plan for, and acts on a dirty working tree.

- To get up to date safely: `git fetch`, then inspect: `git status` (are we behind, ahead, or diverged?) and `git log --oneline HEAD..@{upstream}` (what exactly is incoming?).
- Integrate based on what you saw: behind only — `git merge --ff-only @{upstream}` (fast-forwards or refuses, never invents a merge commit); diverged — decide merge vs. rebase deliberately based on whether local commits are shared, and tell the user if it's not obvious.
- Never pull or merge with uncommitted changes in the tree. Commit or stash (with a message) first.
- Don't update the branch at all unless the task needs it. "Sync first" is not a universal opening move; pulling mid-task can change the code under your feet.
- If a pull/merge you ran starts a conflict you weren't prepared for, `git merge --abort` and reassess rather than resolving under pressure.

**Red flags that you're about to violate this:**

- "First, let me pull to make sure everything's current."
- "git pull is harmless; it just downloads updates."
- "Whatever the pull config does — merge or rebase — is fine."
- "There are uncommitted changes, but the pull will probably leave them alone."
- "Diverged? The pull will sort the histories out automatically."

---

## Why It Works

1. **It splits the trench coat.** The AI treats pull as a download; naming it as fetch-plus-immediate-merge makes the hidden second half — the part that causes all the damage — visible at decision time.
2. **`--ff-only` converts the common case into a no-surprise operation** that either does the safe thing or refuses loudly, replacing config-dependent behavior with an explicit contract.
3. **It challenges "sync first" as an opening ritual.** Much of this failure isn't how the pull is done but that it's done at all, unprompted; making "does this task need upstream changes?" an explicit question removes the ritual.

## Origin

An assistant began a small bug-fix task with a courtesy `git pull`. The branch had diverged, the configured behavior was merge, and three conflicts arrived from a teammate's large refactor. The assistant resolved them — adequately at best — and the eventual PR contained the bug fix plus an unrequested, lightly mangled merge of someone else's refactor. Review took four times longer than the fix warranted, mostly spent asking "why is any of this in here?"
