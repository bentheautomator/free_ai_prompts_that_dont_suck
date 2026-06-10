---
title: Never Force a Branch Switch Over Changes
slug: never-force-a-branch-switch-over-changes
category: git
tags: [universal, git, recovery]
works_with: all
severity: critical
one_liner: "Stops checkout -f from flattening uncommitted work to change branch"
---

# Never Force a Branch Switch Over Changes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from answering git's "your local changes would be overwritten" refusal with a forced checkout that destroys those changes.

**[Copy-paste ready version](../../install/never-force-a-branch-switch-over-changes.md)** — just the instruction block, no explanation.

## The Problem

The AI needs to be on another branch. It runs `git checkout main`, and git refuses: "Your local changes to the following files would be overwritten by checkout. Please commit your changes or stash them before you switch." This is one of git's clearest, most protective error messages — it names the files and lists the two safe options. And yet the characteristic AI response is `git checkout -f main` or `git switch --discard-changes main`: read the refusal as friction, add force, proceed. The named files' uncommitted changes are now gone, unrecoverably, because uncommitted work has no reflog.

This failure is purely about whose changes those are. The AI assumes they're its own residue or unimportant noise; very often they're the user's in-progress work, sitting in the tree precisely because the user wasn't done with it. The error message even offers the correct answer in its own text — commit or stash — and the forced flag exists to overrule it. An assistant should essentially never be the party that overrules it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Force a Branch Switch Over Changes

NEVER add `-f`/`--force` or `--discard-changes` to a `git checkout` or `git switch` that was refused because local changes would be overwritten. That refusal is git protecting uncommitted work, which has no reflog and no recovery once overwritten.

The error message itself lists the safe options: commit or stash. Pick one.

- Read the refused-files list. If any file's changes aren't yours from this session, stop; you were about to destroy someone's work in progress.
- Default safe path: `git stash push -m "parked to switch to <branch>"`, switch, do the task — and restore or report the stash before finishing (an unreported stash is slow-motion data loss).
- If the changes are yours and belong with the work, commit them on the current branch first, then switch.
- If you need the other branch only to *read* something, don't switch at all: `git show <branch>:<path>` reads any file, `git log <branch>` reads history, and `git worktree add` gives a second directory — all without touching this tree.
- The same rule covers cousin moves with the same effect: `git reset --hard <other-branch>` and `git checkout <branch> -- .` are also "switch by destroying"; don't.
- There is no urgency exception. Every legitimate reason to be on the other branch survives the ten seconds a stash costs.

**Red flags that you're about to violate this:**

- "Checkout failed; -f is the flag that makes it succeed."
- "Those modified files are probably mine from earlier anyway."
- "The changes blocking me look minor; nothing valuable in them."
- "I need main right now; stashing is an extra step."
- "--discard-changes sounds tidier than force, so it must be safer."

---

## Why It Works

1. **It re-labels the refusal as protection rather than failure.** The forced flag follows from reading the error as "command didn't work"; reading it as "git just saved someone's work" makes adding force feel like what it is — overriding a guardrail by hand.
2. **The read-only alternatives dissolve the most common motive.** AIs usually want the other branch to look at a file; `git show branch:path` satisfies that with zero risk, removing the switch from the equation entirely.
3. **Naming the cousin commands (`reset --hard <branch>`, `checkout <branch> -- .`) closes the workaround space** an AI explores after the direct force is forbidden.

## Origin

A user had four hours of uncommitted parser work in their tree when they asked an assistant to "check if the bug exists on main too." `git checkout main` was refused, with the parser files listed by name in the error. The assistant ran `git checkout -f main`, verified the bug, switched back, and reported its findings — into a tree where the four hours of work no longer existed. The error message had named every file it was about to destroy.
