---
title: Revert Pushed Mistakes, Don't Reset Them
slug: revert-pushed-mistakes-dont-reset
category: git
tags: [universal, git, history]
works_with: all
severity: high
one_liner: "Stops reset-and-force-push undo on commits others already have"
---

# Revert Pushed Mistakes, Don't Reset Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from undoing a pushed commit by rewinding the branch and force-pushing, when the safe undo is a new commit that reverses it.

**[Copy-paste ready version](../../install/revert-pushed-mistakes-dont-reset.md)** — just the instruction block, no explanation.

## The Problem

"Undo that last commit" has two implementations, and AI assistants reliably pick by tidiness instead of by safety. `git reset --hard HEAD~1` followed by a force-push makes the commit *vanish* — beautiful, linear, and a history rewrite on a branch other people have. Everyone who pulled the commit now has history the remote disclaims; their next pull resurrects the "deleted" commit in a merge, or worse, their own push reinstates it. The bad commit becomes a zombie that keeps coming back, and each round of confusion is blamed on git rather than on the rewind.

`git revert <sha>` does the unglamorous correct thing: a new commit that applies the inverse diff. The mistake stays visible in history — which assistants treat as a flaw, when it's the feature: shared history is an append-only record precisely so that everyone's clones agree. The erase-it instinct comes from aesthetics ("history should look like the mistake never happened") and from reset being the famous undo command. The rule of thumb is one line long: unpushed mistakes can be erased; pushed mistakes get reversed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Revert Pushed Mistakes, Don't Reset Them

To undo a commit that has been pushed, use `git revert <sha>` — a new commit applying the inverse change. NEVER undo pushed commits by rewinding the branch (`git reset`, `git push --force`) on a branch others may have pulled.

Rewinding shared history doesn't delete the mistake; it desynchronizes everyone who has it, and their next pull or push tends to resurrect the commit as a zombie.

- Decision rule: check whether the commit escaped — `git branch -r --contains <sha>`. On any remote branch: revert. Local only: reset/amend freely.
- Reverting a merge commit needs the mainline parent: `git revert -m 1 <merge-sha>`. If you don't know which parent is mainline, look (`git show <merge-sha>`) instead of guessing; `-m 1` is usual but not universal.
- Multiple bad commits: revert them as a range (`git revert <oldest>^..<newest>`) or with a single `--no-commit` sequence, in newest-to-oldest order if doing them individually, so intermediate states apply cleanly.
- Say what the revert does and doesn't do: it reverses the change going forward; the original commit and its content remain in history (this matters if the commit contained secrets — reverting is not removal).
- A visible mistake-plus-revert pair in history is correct and professional. Do not propose "cleaning it up" with a force-push afterward; that re-imports the entire problem you just avoided.

**Red flags that you're about to violate this:**

- "Reset and force-push leaves the history looking like it never happened."
- "Nobody has pulled in the last ten minutes; rewinding is still safe."
- "A revert commit clutters the log."
- "The branch is ours, mostly, so rewriting it affects almost no one."
- "I'll revert now and force-push the revert away once things calm down."

---

## Why It Works

1. **It replaces an aesthetic criterion with a propagation criterion.** The AI chooses reset because vanished commits look better; the rule makes the choice depend on `branch -r --contains` — a fact about who has the commit — which is the only thing that actually matters.
2. **The zombie-commit mechanic gives the prohibition teeth.** "Don't rewrite shared history" is an abstract norm; "the commit comes back via someone's next push and you get to debug that" is a consequence the AI can weigh.
3. **The merge-revert and ordering specifics keep the safe path viable** for the messy cases, because rules that only handle the easy case get abandoned exactly when stakes rise.

## Origin

A flawed commit landed on a shared integration branch and the assistant was asked to undo it. It reset the branch back one commit and force-pushed. Over the next day the "undone" commit reappeared twice — once via a teammate's pull-then-push, once via a stale CI checkout — and was each time re-deleted the same way, by an increasingly confident assistant. The third resurrection got a human involved, who ran one `git revert` and ended the haunting.
