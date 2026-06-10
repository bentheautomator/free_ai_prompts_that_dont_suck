---
title: Stash Safely or Not at All
slug: stash-safely-or-not-at-all
category: git
tags: [universal, git, recovery]
works_with: all
severity: high
one_liner: "Stops careless stash pop and drop from losing stashed work"
---

# Stash Safely or Not at All

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shoving the user's changes into an unlabeled stash and then losing them to a forgotten entry, a conflicted pop, or a casual `stash drop`.

**[Copy-paste ready version](../../install/stash-safely-or-not-at-all.md)** — just the instruction block, no explanation.

## The Problem

The stash is where AI assistants put other people's work to get it out of the way. Branch switch blocked by uncommitted changes? `git stash`, proceed, and — frequently — never restore it. The user's changes are now in an anonymous entry called `WIP on main: 3f2a1c9 fix tests`, invisible in `git status`, waiting to be discovered weeks later or clobbered by `git stash clear`.

The restore side has its own trap: `git stash pop` deletes the stash entry on success, but on conflict it leaves the entry *and* dumps conflict markers into the tree — and assistants, seeing the conflict, often re-stash or reset, compounding the mess. Meanwhile `git stash drop` and `git stash clear` delete actual work with no branch, no reflog entry that's easy to find, and no confirmation prompt. Assistants treat the stash as a temp directory; it's closer to a cliff edge with a shelf on it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stash Safely or Not at All

Treat the stash as a place work can be lost, not a free temp area. Every stash you create must be labeled, accounted for, and restored or reported by the end of the task.

- Always stash with a message: `git stash push -m "user's WIP on auth refactor, stashed to switch branches"`. Anonymous stash entries are how work gets orphaned.
- If you stash someone's changes to unblock an operation, restoring them is part of the task. Before finishing, run `git stash list`; if your entry is still there, restore it or explicitly tell the user it exists and why.
- Restore with `git stash apply`, not `git stash pop`. Apply keeps the entry, so a conflicted or wrong-branch restore loses nothing; drop the entry manually only after confirming the restore is intact.
- NEVER run `git stash drop` or `git stash clear` on entries you did not create in this session. Existing stashes may be the user's parked work.
- If applying a stash conflicts, stop and resolve it like any merge conflict; do not reset the tree or re-stash on top.
- Consider whether a stash is needed at all: committing to a temporary branch (`git checkout -b wip-parking && git commit -am "parking"`) is strictly more durable and visible.

**Red flags that you're about to violate this:**

- "I'll stash this quickly; no time for a message."
- "Stash pop is the normal way to get things back."
- "These old stash entries are clutter; I'll clear them."
- "The user's changes are safe in the stash, my task here is done."
- "The pop conflicted, so I'll just stash everything again and move on."

---

## Why It Works

1. **It attaches a completion obligation to the stash.** The core failure is asymmetry — stashing serves the AI's immediate goal, restoring serves nobody's — so the rule makes `git stash list` part of "done," closing the loop the AI otherwise abandons.
2. **Apply-over-pop converts the one destructive moment into a reversible one.** Pop's delete-on-success behavior is the only reason a botched restore loses data; removing pop removes the failure mode.
3. **The session-ownership line on drop/clear blocks collateral damage** to entries the AI never created and cannot evaluate.

## Origin

A user asked their assistant to check whether a bug existed on the release branch. The assistant stashed the user's uncommitted day of work to switch branches, investigated, reported its findings — and switched back without restoring. Two weeks and several stashes later, the user ran a tutorial's `git stash clear` while cleaning up. The day of work was gone, and the postmortem's only consolation was the lesson.
