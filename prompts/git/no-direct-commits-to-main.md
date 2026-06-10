---
title: No Direct Commits to Main
slug: no-direct-commits-to-main
category: git
tags: [universal, git, branches]
works_with: all
severity: high
one_liner: "Stops commits landing directly on main instead of a branch"
---

# No Direct Commits to Main

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from committing work straight onto the default branch when it should have created a feature branch first.

**[Copy-paste ready version](../../install/no-direct-commits-to-main.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant finishes a change, runs `git commit`, and only then does anyone notice the current branch was `main`. The work skipped review, skipped CI gates that only run on pull requests, and is now tangled into the default branch's history. If the repo has push protection, the damage surfaces later as a confusing rejected push; if it doesn't, unreviewed code just shipped.

Assistants commit to whatever branch is checked out because branch selection isn't part of the "make a commit" recipe — `git commit` works the same everywhere, so they never look. Humans working in the repo earlier may have left `main` checked out, and the assistant inherits that state silently. Checking the current branch is a one-command habit, but nothing in the commit workflow forces it, so it has to be installed as a rule.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Direct Commits to Main

NEVER commit directly to `main`, `master`, `develop`, or any release branch. Always work on a feature branch.

Committing to the default branch bypasses review and PR-based checks, and untangling a commit from main is far harder than creating a branch would have been.

- Before your first commit in any session, run `git branch --show-current`. If it prints a protected branch name, create a branch first: `git checkout -b <type>/<short-description>` (e.g. `fix/login-timeout`).
- If you discover uncommitted work sitting on main, branch from right where you are; the changes come with you: `git checkout -b fix/whatever`. Do not commit "just this once" on main.
- If you discover you already committed to main but have not pushed, move the work: `git branch fix/whatever && git reset --hard origin/main` only after confirming with `git status` that nothing uncommitted will be lost, then check out the new branch.
- If the commit on main is already pushed, stop and tell the user; the fix depends on team policy and is not yours to choose.
- Only commit to main when the user explicitly instructs it for this specific commit.

**Red flags that you're about to violate this:**

- "Main is checked out, so that's where the user wants this."
- "It's a one-line fix; a branch is overkill."
- "I'll commit here and move it to a branch later if needed."
- "This repo looks like a solo project; branch discipline doesn't apply."
- "Creating a branch will interrupt my flow; commit first, sort it out after."

---

## Why It Works

1. **It inserts a check where none exists naturally.** `git commit` carries no branch awareness, so the rule attaches one (`git branch --show-current`) to the start of the workflow, before the cheap moment to branch has passed.
2. **It pre-writes the recovery for both failure stages** (uncommitted-on-main, committed-but-unpushed), so the AI doesn't improvise something destructive like resetting main with work still uncommitted.
3. **"One-line fix" is named as a rationalization**, which matters because trivial changes are precisely the ones assistants ship straight to main — the perceived stakes are low at exactly the moment the habit forms.

## Origin

A developer left `main` checked out over lunch. Their assistant, asked afterward to "fix the date parsing bug and commit," did exactly that — onto main — and the auto-deploy that watched the branch shipped the unreviewed change to production within minutes. The fix happened to be correct; the next one made the same way wasn't, and that incident is why the rule exists.
