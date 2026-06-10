---
title: Abort Cleanly, Don't Improvise Mid-Operation
slug: abort-cleanly-dont-improvise-mid-operation
category: git
tags: [universal, git, recovery]
works_with: all
severity: high
one_liner: "Stops improvised resets during a half-done merge, rebase, or pick"
---

# Abort Cleanly, Don't Improvise Mid-Operation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from responding to a stuck merge, rebase, or cherry-pick with improvised resets instead of the operation's own --abort/--continue controls.

**[Copy-paste ready version](../../install/abort-cleanly-dont-improvise-mid-operation.md)** — just the instruction block, no explanation.

## The Problem

Merges, rebases, cherry-picks, and reverts are stateful operations: when they stop on a conflict, the repo is deliberately paused, with metadata in `.git` tracking exactly where things stand. Each one ships a full set of controls — `--continue`, `--abort`, `--skip` — that either finish the job or restore the pre-operation state perfectly. AI assistants in this situation routinely use none of them. They see scary `git status` output, conclude something is broken, and start freelancing: `git reset --hard`, deleting `.git/MERGE_HEAD` by hand, committing the half-resolved tree, or stacking a new merge on top of the stuck one.

Every one of those moves makes things worse. Committing mid-rebase bakes conflict markers and partial resolutions into history. A hard reset mid-merge throws away both the operation and any resolution work, and can leave stale state files that confuse the next command. The paused state was never the problem — it was the operation politely waiting for a decision, and the decision menu has exactly three buttons on it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Abort Cleanly, Don't Improvise Mid-Operation

When a merge, rebase, cherry-pick, or revert stops partway, use that operation's own controls — `--continue`, `--abort`, `--skip` — and nothing else. NEVER improvise with resets, manual `.git` file deletion, or new commits while an operation is in progress.

A paused operation is not a broken repo; it is git waiting for your decision, with a guaranteed exit (`--abort`) back to the exact pre-operation state.

- First, identify what's in progress: `git status` names it explicitly ("You are currently rebasing", "All conflicts fixed but you are still merging"). Believe that line over your assumptions.
- To proceed: resolve the conflicts properly, `git add` the resolved files, then `git rebase --continue` / `git merge --continue` / `git cherry-pick --continue`. Do not use plain `git commit` to finish a rebase or pick; `--continue` preserves the operation's metadata and authorship.
- To back out: `git <operation> --abort`. This is always safe and always available; prefer it over any clever salvage when you're unsure.
- NEVER: `git reset --hard` mid-operation, deleting `.git/MERGE_HEAD` or `.git/rebase-merge/` manually, starting a second merge/rebase on top of a stuck one, or stashing your way around the pause.
- If even `--abort` fails or the state defies the menu, stop and report the exact `git status` output to the user instead of escalating force.

**Red flags that you're about to violate this:**

- "The repo is in a weird state; a hard reset will normalize it."
- "I'll just commit what's resolved so far and clean up after."
- "Deleting the MERGE_HEAD file should clear this stuck merge."
- "git status looks broken; standard commands clearly aren't working."
- "I'll start a fresh rebase over this one; it'll overwrite the stuck state."

---

## Why It Works

1. **It reframes "stuck" as "paused with a menu."** The improvisation reflex comes from reading the paused state as breakage; once the AI knows `--abort` is a guaranteed clean exit, the scary state has a safe default and force loses its appeal.
2. **It anchors on `git status`'s own narration** — the one source that states exactly which operation is in progress — replacing the AI's guesswork about what's wrong with text that's already on screen.
3. **The explicit never-list covers the actual observed failure moves** (mid-operation reset, manual state deletion, commit-instead-of-continue), each of which feels locally reasonable and is named here precisely so it can be recognized and refused.

## Origin

A cherry-pick stopped on a conflict, and the assistant — apparently unaware `--abort` existed — committed the conflicted files, markers and all, then ran `git reset --hard HEAD~1` to undo *that*, which also discarded the user's resolution work from a separate paused merge. The final state took a senior engineer forty minutes of reflog spelunking to reconstruct. The original conflict had been one line.
