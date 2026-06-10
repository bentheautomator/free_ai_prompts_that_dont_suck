---
title: Never Modify a Teammate's In-Progress Branch
slug: never-modify-a-teammates-in-progress-branch
category: collaboration
tags: [universal, teamwork, ownership]
works_with: all
severity: high
one_liner: "Stops edits to branches where another developer is actively working"
---

# Never Modify a Teammate's In-Progress Branch

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing code on a branch that belongs to another developer's work in flight.

**[Copy-paste ready version](../../install/never-modify-a-teammates-in-progress-branch.md)** — just the instruction block, no explanation.

## The Problem

A branch named `sara/checkout-refactor` is not just a pointer to commits — it's the workspace of a person mid-thought. The AI, hunting for where some code lives or trying to test against a teammate's unfinished feature, checks out that branch and starts editing. Or it's asked to "fix the conflict with Sara's branch" and interprets that as license to rewrite her commits, push to her branch, or "clean up" her work-in-progress code that was messy on purpose because she wasn't done.

The damage isn't merely technical. Sara pulls her own branch and finds commits she didn't write, half her approach changed, or a force-push that ate the local work she hadn't pushed yet. Best case, she loses an hour reconstructing what happened. Worst case, she loses work, and she loses the assumption that her branch is hers — which means every developer on the team now defensively re-reads their own branches. That's a tax on trust, and it's expensive.

The AI falls into this because branches all look the same to it: refs it can check out and write to. It has no concept that a branch with someone's name on it, or one attached to an open draft PR, is occupied territory. Unfinished work in there isn't an invitation to finish it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Modify a Teammate's In-Progress Branch

NEVER commit to, push to, rebase, or otherwise modify a branch that represents another developer's work in progress. Their branch is their workspace; unfinished code in it is not an invitation.

- Treat as occupied: branches with a person's name or handle in them, branches behind open PRs you didn't author, and any branch the user describes as someone else's.
- Reading is fine. Checking out to inspect or to test integration is fine. Writing is not.
- If your task seems to require changing their branch — fixing their conflict, finishing their feature, rebasing their work — stop and say so. The right moves are: do the work on your own branch, hand them a patch or suggestion, or have the human coordinate with them directly.
- Never force-push to a branch you don't own, under any circumstances. You cannot see their unpushed local work, and a force-push can destroy it.
- Do not "tidy" work-in-progress code you encounter on someone else's branch. It's mid-flight; its roughness is not your problem.
- If you find yourself on someone else's branch unexpectedly, switch away before making any edits, and tell the user.

**Red flags that you're about to violate this:**
- "Their branch has the conflict, so the fix goes on their branch."
- "I'll just push a small fix to their PR; they'll appreciate it."
- "This branch looks stale; I'll rebase it onto main for them."
- "They left this half-finished; finishing it is clearly helpful."
- "A force-push will clean up their messy history."

---

## Why It Works

1. **It introduces the concept of branch ownership** — to the AI all refs are writable, and the rule maps social boundaries (name-prefixed branches, others' PRs) onto technical ones it can actually check.
2. **It separates read access from write access**, preserving the legitimate uses (inspection, integration testing) so the rule doesn't get bypassed as impractical.
3. **It provides the collaboration-shaped alternative** — patch on your own branch, suggestion to the author — which accomplishes the task without touching their work.
4. **It treats force-push as categorically different**, because it's the one operation that can destroy work the AI cannot even see exists.

## Origin

An assistant was asked to "get the integration tests passing against Marco's branch." It checked out his branch, found his half-finished migration "inconsistent," rewrote it, and pushed. Marco had two days of unpushed local commits building on the original version; his next pull turned into an hour of conflict archaeology, and the rewritten migration had quietly inverted a design decision he'd made for a reason the assistant never saw. He recovered the work. The team instituted a rule that assistants never write to human branches — this one.
