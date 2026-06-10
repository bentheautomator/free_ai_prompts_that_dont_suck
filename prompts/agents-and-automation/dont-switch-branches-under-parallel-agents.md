---
title: Don't Switch Branches Under Parallel Agents
slug: dont-switch-branches-under-parallel-agents
category: agents-and-automation
tags: [universal, agents, multi-agent]
works_with: all
severity: high
one_liner: "A git checkout that yanks the working tree out from under sibling sessions"
---

# Don't Switch Branches Under Parallel Agents

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from changing shared git state — branch, staging area, stash — while other sessions are working in the same checkout.

**[Copy-paste ready version](../../install/dont-switch-branches-under-parallel-agents.md)** — just the instruction block, no explanation.

## The Problem

Git state is per-checkout, not per-session. When an agent runs `git checkout feature-b` in a repository where another agent — or the user — is mid-task, every file in the working tree changes for everyone at once. The sibling agent's next read returns code from a different branch than its last read; its next edit applies feature-A logic to feature-B files; its in-flight test run is now testing a chimera. Nobody told the sibling the world changed, because git doesn't broadcast and agents don't check.

Branch switching is only the loudest version. `git stash` vacuums up the sibling's uncommitted work along with the agent's own. `git add -A` stages a mixture of two agents' changes, and the commit that follows publishes the blend under one name. `git reset` unstages a sibling's carefully staged hunks. Each of these commands operates on the whole checkout while feeling, to the agent issuing it, like a private action — that's the core misunderstanding. There is exactly one HEAD, one index, one stash stack, and everyone in the checkout is holding them jointly.

Agents reach for these commands mid-task for sensible-sounding reasons — comparing against another branch, cleaning the slate, organizing a commit — with no model that the slate is shared. The user often discovers the collision as an incoherent diff: half their feature mysteriously interleaved with someone else's.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Switch Branches Under Parallel Agents

NEVER change shared git state — current branch, staging area, stash, or working tree-wide resets — in a checkout where another session (human or agent) may be working. Git state belongs to the checkout, not to you; there is one HEAD, one index, and one stash stack, held jointly by everyone in the directory.

The core problem: branch switches and resets feel like private actions but rewrite every file for every concurrent session, none of which get notified that their world changed.

- Assume the checkout is shared unless you know otherwise: the user runs editors and terminals you can't see, and may run parallel agent sessions. Uncommitted changes you didn't make are proof of a co-worker, not clutter.
- Commands that change shared state and therefore need either certainty you're alone or explicit user approval: `git checkout <branch>` / `git switch`, `git stash` (it captures everyone's uncommitted work), `git reset` in any form, `git rebase`, `git merge`, and `git clean`.
- Need another branch's contents while others work? Read without switching: `git show other-branch:path/to/file`, `git diff main...feature`, or create a separate worktree (`git worktree add`) and work there. Worktrees give every session its own HEAD and index — they are the actual fix for parallel work.
- Stage surgically in shared checkouts: add files by name, only files you changed. Never `git add -A` or `git add .` where someone else's modifications could be sitting.
- Before committing in a shared checkout, review the staged diff and confirm every hunk is yours. A commit blending two sessions' work is a mess that lands under your name.
- If you discover the branch changed under YOU, stop editing immediately and re-orient: confirm the branch, re-read files you're touching, and ask the user what happened before writing anything.

**Red flags that you're about to violate this:**
- "Let me quickly check out main to compare..."
- "I'll stash everything to get a clean slate..."
- "git add -A and commit, then back to work..."
- "These uncommitted changes aren't mine — I'll reset them..."
- "Nobody else is using this repo right now..." (verify, don't assume)

---

## Why It Works

1. **It corrects the ownership model.** Agents treat git commands as session-local because everything else they do is. Stating "one HEAD, one index, one stash — held jointly" makes the shared blast radius part of the command's meaning.

2. **It provides non-mutating equivalents for every motive.** Compare via `git show` and `diff`, isolate via worktrees, organize via named staging. Each legitimate reason to touch shared state gets a route that doesn't, so the rule never blocks the underlying need.

3. **It flags foreign changes as a presence signal.** The most destructive move — resetting or stashing "clutter" that is actually a sibling's live work — is preempted by redefining unexplained changes as evidence of a co-worker.

4. **It covers the victim side.** Teaching the agent to detect and stop when the branch moved under it converts the second half of every collision from compounding damage into a clean halt.

## Origin

While one agent ran a long migration on a feature branch, a second session in the same checkout switched to main "briefly, to verify a baseline behavior." The first agent's in-progress edits were now being applied against main's versions of the files; eleven edits landed before anyone noticed, producing a working tree that belonged to no branch at all. Untangling which hunks were intended for which branch took the user most of an afternoon with `git diff` and increasingly strong coffee. A worktree would have cost one command.
