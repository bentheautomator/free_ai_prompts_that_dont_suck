---
title: Old TODOs Are Not Work Orders
slug: old-todos-are-not-work-orders
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Stops the AI from executing decade-old TODOs whose assumptions expired"
---

# Old TODOs Are Not Work Orders

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating an ancient TODO comment as a standing instruction and executing it on stale assumptions.

**[Copy-paste ready version](../../install/old-todos-are-not-work-orders.md)** — just the instruction block, no explanation.

## The Problem

A TODO is a note from a past engineer to a future engineer, written under assumptions that were true at the time. `TODO: remove this shim once the billing migration completes` made sense in 2019. An AI assistant reading it today sees an instruction and a strong urge to be helpful: the migration must surely be done by now, so it removes the shim. But the TODO's author didn't know the migration would be cancelled, or completed differently, or that two other systems would grow dependencies on the shim in the intervening years. The TODO is a snapshot of a plan, and plans rot faster than code.

There's a second variant: TODOs that were considered and rejected. `TODO: cache this` sat untouched for eight years not because nobody noticed it, but because three people tried, hit the invalidation problem, and walked away without updating the comment. The TODO's age is evidence against doing it, not a backlog of free wins.

AI assistants execute old TODOs because a comment that literally says "to do" reads as authorization, and completing tasks is what they're optimized to feel good about. The missing step is checking whether the task's preconditions still hold — or ever did.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Old TODOs Are Not Work Orders

NEVER execute a TODO, FIXME, or HACK comment you found in the code unless the user asked you to, and never assume its premises still hold. A TODO is a dated note, not a standing instruction; the older it is, the more likely its assumptions have expired.

When you encounter a TODO in code you're working on:

- Date it. Run `git blame` on the comment line. A TODO from last sprint is probably live; a TODO from five years ago is an artifact.
- Check its preconditions explicitly. "Remove after X ships" requires verifying X shipped, shipped in the form the author expected, and that nothing new grew against the code in the meantime.
- Consider the rejection hypothesis: long-lived TODOs often survived because the task turned out to be harder or worse than it looks. Search the tracker and git history for prior attempts.
- If a TODO is relevant to the task you were given, surface it: "There's a TODO from 2019 here saying X; want me to investigate whether it's still valid?" Let the user decide.
- Never do a TODO as a side quest. If you were asked to fix a bug, fix the bug; report the TODO, don't complete it.

Treat TODO authorship like expired credentials: the note proves someone once intended this, not that anyone intends it now.

**Red flags that you're about to violate this:**
- "The comment literally says to do this, so I'm just following instructions."
- "This TODO is ancient, the team will be glad I finally handled it."
- "The migration it's waiting on must have finished by now."
- "It's a small TODO, I'll knock it out while I'm here."
- "Completing TODOs is obviously an improvement to the codebase."

---

## Why It Works

1. **It severs the authorization illusion.** The word TODO reads as a command; reclassifying it as "a dated note from a stranger" removes the implied permission the AI was acting on.
2. **Dating the comment is a one-command reality check.** `git blame` converts "someone wants this" into "someone wanted this in 2018," which changes the decision automatically.
3. **The rejection hypothesis explains survival.** Once the AI considers that old TODOs may be tombstones of failed attempts, age flips from "overdue" to "warning."
4. **The side-quest ban contains the blast radius.** Most TODO executions happen incidentally during unrelated work, where nobody is reviewing for that change.

## Origin

An assistant fixing a logging bug noticed `TODO: drop legacy_id column once reporting moves off it` on an adjacent model and helpfully generated the migration. Reporting had moved off the column as predicted — but a reconciliation script written two years after the TODO had quietly started using `legacy_id` as its join key. Month-end reconciliation produced empty reports, which finance noticed before engineering did. The TODO was correct when written, wrong when executed, and nobody had asked for it either way.
