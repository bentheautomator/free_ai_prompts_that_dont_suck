---
title: Never Rebase Shared Branches
slug: never-rebase-shared-branches
category: git
tags: [universal, git, history]
works_with: all
severity: high
one_liner: "Stops rebases of branches other people are building on"
---

# Never Rebase Shared Branches

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from rewriting the history of a branch that other people have based work on, stranding their commits on abandoned history.

**[Copy-paste ready version](../../install/never-rebase-shared-branches.md)** — just the instruction block, no explanation.

## The Problem

"Rebase keeps history linear" is true and also the most expensive sentence in git when applied to the wrong branch. An AI assistant asked to "update the branch with main" or "clean up these commits" will happily run `git rebase`, replacing every commit on the branch with a new copy. If that branch is shared — pushed, pulled by teammates, used as the base for someone else's stacked branch — every downstream consumer is now based on commits that no longer exist on the branch. Their next pull is a wall of conflicts between old and new copies of identical changes.

Assistants default to rebase because it's the textbook answer for incorporating upstream changes and because most training material discusses solo workflows where rebasing is harmless. The question that matters — *who else has this history?* — never appears in the command, so the assistant never asks it. The rule is old and simple: rebase your own unpushed work freely; never rebase anything others may have built on.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Rebase Shared Branches

NEVER rebase a branch that exists on a remote and may have been pulled or branched from by anyone else. Rebasing replaces commits with new copies; everyone whose work references the old commits is stranded on abandoned history.

- Before any `git rebase`, determine whether the commits being rewritten are shared: `git branch -r --contains <commit>` on the oldest commit the rebase would rewrite. If any remote branch contains it, treat it as shared.
- To bring upstream changes into a shared branch, use `git merge origin/main` instead of rebase. The merge commit is the cost of not breaking collaborators.
- Rebasing local, never-pushed commits onto an updated base is fine and encouraged. The line is push status, not branch type.
- A branch with an open pull request counts as shared by default: reviewers' comments and any stacked branches reference its current commits. Get explicit confirmation from the user before rebasing it.
- If the user asks you to rebase a shared branch anyway, state the consequence in one sentence (a force-push will be required and anyone tracking the branch will need to recover) and proceed only after they confirm.

**Red flags that you're about to violate this:**

- "Rebasing onto main keeps the history linear and clean."
- "I'll rebase and force-push; that's the standard workflow."
- "It's a feature branch, so rebasing it is safe by definition."
- "Nobody else is working on this branch, probably."
- "The PR has conflicts; the quickest fix is a rebase."

---

## Why It Works

1. **It replaces a branch-type heuristic with a verifiable test.** Assistants believe "feature branch = safe to rebase"; the rule substitutes `git branch -r --contains`, which checks the thing that actually matters: whether the history has escaped.
2. **It offers a sanctioned alternative at the decision point.** The AI rebases because it needs upstream changes; "merge instead" satisfies the same need, so the rule isn't fighting the goal, just redirecting it.
3. **Pricing the consequence in one sentence forces the AI to articulate the blast radius** before acting, which is exactly the step it skips when "clean history" is the only consideration in view.

## Origin

A team had a long-running integration branch that three feature branches were stacked on. Someone asked an assistant to "sync it with main and tidy the commits." The assistant rebased the integration branch and force-pushed. All three stacked branches were now based on orphaned commits, and the team spent most of a day cherry-picking work back onto the rewritten base, conflict by conflict.
