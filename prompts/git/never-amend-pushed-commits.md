---
title: Never Amend Pushed Commits
slug: never-amend-pushed-commits
category: git
tags: [universal, git, history]
works_with: all
severity: high
one_liner: "Stops amending commits that already exist on the remote"
---

# Never Amend Pushed Commits

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rewriting a commit that teammates have already pulled, forcing a force-push and breaking everyone downstream.

**[Copy-paste ready version](../../install/never-amend-pushed-commits.md)** — just the instruction block, no explanation.

## The Problem

The AI makes a small follow-up fix, notices it belongs with the previous commit, and runs `git commit --amend`. Tidy instinct, wrong context: that previous commit was pushed twenty minutes ago. Now local and remote history have diverged, the next `git push` is rejected, and the AI "solves" that with a force-push. Anyone who pulled the original commit now has a broken branch, and their next pull produces a confusing merge of two versions of the same commit.

Assistants love `--amend` because it produces clean history and avoids a "fix typo" commit. They almost never check whether the commit has left the machine first, because nothing in the command requires it. Amending is only free while the commit is private; the moment it's on a remote that anyone else can fetch from, amending is a history rewrite with all the costs that implies.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Amend Pushed Commits

NEVER run `git commit --amend` on a commit that has been pushed to a remote. Amending rewrites the commit; if the original is already on the remote, you have forked history and the only way forward is a force-push that breaks everyone who pulled it.

- Before any `--amend`, verify the commit is local-only: `git log --oneline @{upstream}..HEAD` must include HEAD. If there is no upstream, check `git branch -r --contains HEAD`; if any remote branch contains it, do not amend.
- If the commit is already pushed, make a new commit instead. A small `fix: correct typo in previous change` commit is correct; rewritten shared history is not.
- This applies to all forms: `--amend`, `--amend --no-edit`, and amend-equivalents like `git rebase` onto a parent of a pushed commit.
- The sole exception is when the user explicitly confirms the branch is theirs alone and asks for the rewrite, after you state that a force-push will be required.
- Never chain amend with push: if you find yourself planning `--amend` followed by `push --force`, stop and report instead.

**Red flags that you're about to violate this:**

- "This tiny fix belongs in the last commit, I'll just amend it."
- "Amending keeps the history clean."
- "It was only pushed a minute ago, nobody has pulled it yet."
- "I'll amend now and deal with the push rejection later."
- "The commit message has a typo; a quick amend will fix it."

---

## Why It Works

1. **It supplies the missing precondition check.** `--amend` carries no built-in guard about remote state; the rule wires one in (`@{upstream}..HEAD`), turning an invisible assumption into a command the AI actually runs.
2. **It reframes "clean history" as the trap.** The AI's motive for amending is tidiness; the rule explicitly prices the tidiness against a force-push, so the cheaper option (a follow-up commit) wins.
3. **Banning the amend-then-force-push chain closes the recovery loophole.** Without it, the AI treats the rejected push as a new problem to "fix" rather than evidence it already made a mistake.

## Origin

An assistant was asked to fix a typo in a commit message. The commit was on a shared feature branch, pushed an hour earlier and already pulled by two teammates. The assistant amended, hit the rejected push, force-pushed, and both teammates spent their next pull untangling duplicate commits and a phantom merge. The typo had been in a word nobody would ever have read again.
