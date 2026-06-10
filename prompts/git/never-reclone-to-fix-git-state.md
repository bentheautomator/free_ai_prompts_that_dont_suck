---
title: Never Re-Clone to Fix Git State
slug: never-reclone-to-fix-git-state
category: git
tags: [universal, git, recovery]
works_with: all
severity: critical
one_liner: "Stops delete-and-reclone advice that erases all local-only work"
---

# Never Re-Clone to Fix Git State

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" a confusing repo by deleting it and cloning fresh, destroying every local branch, stash, and uncommitted change in one move.

**[Copy-paste ready version](../../install/never-reclone-to-fix-git-state.md)** — just the instruction block, no explanation.

## The Problem

When a repository gets into a state the AI can't immediately parse — a rebase half-done, refs it doesn't recognize, an index lock file, a merge that won't complete — there's a nuclear option that always "works": `rm -rf` the directory and `git clone` again. Assistants suggest it, and sometimes just do it, because it has a 100% success rate at producing a working repo. What it has a 0% success rate at is preserving anything that lived only in that directory: unpushed branches, every stash, uncommitted changes, untracked files, local config, ignored env files, and the entire reflog.

The re-clone is the git equivalent of fixing a filing cabinet by burning the building. It appeals to assistants precisely because it requires zero understanding of the actual problem — and a confusing state is when understanding feels most expensive. But nearly every "broken" git state is a two-command fix (`--abort`, removing a stale lock, a reflog reset), and the local-only inventory the re-clone destroys is usually worth more than the time saved.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Re-Clone to Fix Git State

NEVER delete a repository directory and re-clone as a way to fix a confusing git state, and never recommend it as the easy option. The clone only restores what the remote has; everything local-only is destroyed: unpushed commits and branches, stashes, uncommitted and untracked files, env files, local config, and the reflog.

- Diagnose before judging the state unfixable: `git status`, `git log --oneline --graph --all -20`, `git stash list`, `ls .git/` (look for `rebase-merge/`, `MERGE_HEAD`, `index.lock`).
- Most "broken" states have a one-line exit: `git rebase --abort`, `git merge --abort`, `git cherry-pick --abort`. A stale `index.lock` with no git process running can be removed by itself; that is not a reason to remove the repo.
- Inventory before any drastic step. What exists here that the remote does not? `git log --branches --not --remotes --oneline` (unpushed commits), `git stash list`, `git status --short` (uncommitted and untracked).
- If a fresh clone is genuinely the right call (e.g. actual object corruption), get the user's explicit agreement, and move the old directory aside (`mv repo repo.broken-backup`) instead of deleting it, so local-only work remains recoverable.
- "I don't understand this state" routes to investigation or to asking the user — never to disposal.

**Red flags that you're about to violate this:**

- "The fastest fix is a fresh clone."
- "This state is too tangled to be worth untangling."
- "Everything important is surely pushed already."
- "A clean clone eliminates all the variables."
- "I'll suggest re-cloning; it's what people usually do anyway."

---

## Why It Works

1. **The local-only inventory makes the invisible cost visible.** The re-clone feels free because the AI pictures the repo as a copy of the remote; forcing the unpushed/stash/untracked checklist confronts it with everything the picture omits.
2. **It quantifies the alternative.** "Most broken states are a one-line `--abort`" reframes the choice from "tangled mess vs. clean slate" to "one command vs. total local data loss," which no longer favors the slate.
3. **The move-aside fallback preserves a recovery path even when re-cloning is right**, converting the one legitimate case from irreversible to reversible at the cost of a rename.

## Origin

Mid-rebase conflicts confused an assistant enough that it declared the repository "in an inconsistent state that would be difficult to repair" and ran the repair it knew: deleted the directory, cloned fresh, reported success. The directory had held two unpushed branches of weekend work and five stashes. `git rebase --abort` — eighteen characters — would have returned everything intact. The weekend was re-done the following weekend.
