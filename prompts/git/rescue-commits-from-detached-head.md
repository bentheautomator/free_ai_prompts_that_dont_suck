---
title: Rescue Commits From Detached HEAD
slug: rescue-commits-from-detached-head
category: git
tags: [universal, git, recovery]
works_with: all
severity: high
one_liner: "Stops detached-HEAD commits from being orphaned by a branch switch"
---

# Rescue Commits From Detached HEAD

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from committing on a detached HEAD and then checking out a branch, abandoning the new commits with no name pointing to them.

**[Copy-paste ready version](../../install/rescue-commits-from-detached-head.md)** — just the instruction block, no explanation.

## The Problem

Detached HEAD happens innocently: the AI checks out a tag to inspect a release, checks out a commit hash while investigating, or lands there after a submodule operation. Git prints a perfectly clear warning that almost nothing reads. The AI then proceeds with its task — edits files, makes commits — and those commits exist only as a chain hanging off HEAD, with no branch name pointing at them. The moment the AI runs `git checkout main` to "get back to normal," the chain is unreferenced. Git even prints the rescue command in its warning at that point; assistants scroll past that too.

The second-order failure is panic: an assistant that *notices* "detached HEAD" in `git status` often treats it as an error state to escape immediately, checking out a branch reflexively — which is precisely the move that strands any commits made there. Detached HEAD is not an emergency. It's a fine place to look around and a terrible place to leave work.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rescue Commits From Detached HEAD

Before switching away from a detached HEAD, check whether you made commits there. If you did, give them a branch name first; switching away without one orphans the commits.

- Know when you're detached: `git status` says "HEAD detached at <ref>" and `git branch --show-current` prints nothing. Check after any checkout of a tag, commit hash, or `origin/<branch>`.
- Detached HEAD is a normal state for *reading* — inspecting old code, running tests against a release. Do not panic-escape it, and do not start *writing* there if you can branch first: `git switch -c investigate-v2-bug v2.0.1`.
- If you already committed on a detached HEAD, anchor the work before any checkout: `git branch rescue/<description> HEAD`, then switch wherever you need; the commits now have a name.
- If you realize you switched away and left commits behind, recover immediately: `git reflog` shows the abandoned tip; `git branch rescue/<description> <sha>` saves it. Git's own "leaving behind" warning prints the sha — read it instead of scrolling past.
- Never run history-altering or destructive commands (`rebase`, `reset --hard`) while detached; fix your footing first.

**Red flags that you're about to violate this:**

- "Detached HEAD sounds broken; I'll checkout main to fix it."
- "I'll just make this small commit here and sort out branches later."
- "The warning git printed is boilerplate."
- "My commits are in the repo somewhere; switching branches can't hurt them."
- "I don't need a branch for a quick experiment."

---

## Why It Works

1. **It de-pathologizes the state.** Half the damage comes from treating "detached HEAD" as an error to flee; defining it as normal-for-reading removes the reflex that strands commits.
2. **The pre-switch question ("did I commit here?") is positioned at the exact moment of loss** — orphaning happens at checkout, so that's where the rule installs the check, not at some general "be careful" level.
3. **It pre-loads the recovery sequence** (`reflog`, `branch rescue/`), so even when the failure happens, the AI executes a two-command fix instead of declaring the work lost or recreating it.

## Origin

An assistant checked out an old release tag to reproduce a reported bug, found it, and — staying right where it was — wrote and committed a fix plus a regression test. Then it checked out `main` to "apply the fix properly," found the working tree clean, and reported that the fix "appeared to have been lost," offering to rewrite it. The two commits sat unreferenced in the object store the whole time; one `git reflog` would have named them.
