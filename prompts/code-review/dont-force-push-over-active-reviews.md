---
title: Don't Force-Push Over an Active Review
slug: dont-force-push-over-active-reviews
category: code-review
tags: [universal, review, workflow]
works_with: all
severity: medium
one_liner: "Stops history rewrites that orphan a reviewer's in-progress line comments"
---

# Don't Force-Push Over an Active Review

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents rewriting branch history mid-review, which detaches the reviewer's line comments from the code they were about.

**[Copy-paste ready version](../../install/dont-force-push-over-active-reviews.md)** — just the instruction block, no explanation.

## The Problem

A reviewer is halfway through a 400-line PR, leaving line comments as they go. Meanwhile the assistant, asked to address the first batch of feedback, decides the commit history is untidy, squashes everything into one clean commit, rebases on main, and force-pushes. Every pending and posted line comment is now anchored to commits that no longer exist. GitHub shows them as "outdated" at best, orphaned at worst; the "changes since your last review" view is gone; the reviewer has to start over from the full diff.

Assistants do this because they've absorbed the (correct, in other contexts) norm that clean history is good and rebasing is hygienic. They optimize the artifact — tidy commits — without modeling the reviewer as a stateful process whose state lives in commit SHAs. Force-pushing during review doesn't clean anything up; it deletes another person's work in progress.

The cost is concrete: re-review takes longer than first review of the same diff, because the reviewer must re-verify things they already checked but can no longer prove they checked. Some won't bother, and will skim-approve instead. That's how reviewed-looking unreviewed code merges.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Force-Push Over an Active Review

NEVER force-push, rebase, squash, or amend commits on a PR branch once review has started, unless the reviewer explicitly asks for it or the platform requires it (e.g., a conflicting base that blocks merge). Address feedback with new commits appended on top.

A reviewer's line comments and "viewed" state are anchored to commit SHAs. Rewriting history destroys that state — you are deleting the reviewer's working notes.

- During review: fix-up commits only. `git commit -m "address review: handle empty payload"` and a normal push.
- "Messy history" is not a reason. Most platforms squash on merge anyway; tidy it then, not now.
- If a rebase is genuinely required (merge conflict with main, broken base), say so in the thread first, wait for acknowledgment, and after pushing, post the old and new head SHAs so the reviewer can diff across the rewrite.
- Never use `--force`; if you must rewrite with consent, use `--force-with-lease`.
- "Review has started" means: any comment, any pending review, or a requested reviewer who said they're looking. When unsure, assume it has.

**Red flags that you're about to violate this:**

- "I'll just squash these fixup commits so the history looks professional..."
- "Rebasing on main now will save trouble later..."
- "The reviewer hasn't commented in an hour, they're probably done..."
- "Their comments are on old code anyway, outdated is fine..."
- "I'll amend the last commit instead of adding a noisy new one..."

---

## Why It Works

1. **It models the reviewer as stateful.** The rule's framing — comments are anchored to SHAs, rewriting deletes someone's notes — gives the model a mechanical reason, not a courtesy, so "but clean history is good" stops winning the argument.
2. **Append-only has a verifiable shape.** "New commits on top" is easy for the model to check it's complying with; "be considerate" is not.
3. **The consent-plus-SHAs escape hatch covers the legitimate case.** Rebases that are truly necessary still happen, but with a handoff that lets the reviewer reconstruct what they'd already covered.
4. **Defaulting "unsure" to "review started" closes the loophole** where the model decides nobody is looking and rewrites anyway.

## Origin

A reviewer spent an evening leaving twenty-three line comments on a gnarly migration PR, finishing with "will do the second half tomorrow." Overnight, the assistant squashed nine commits into one and rebased onto main to "prepare for merge." By morning, every comment was orphaned, the partial-review checkpoint was gone, and the reviewer — facing the full diff again — approved after a ten-minute skim. The data-loss bug in the second half, the half that was never actually re-read, ran in production for a week.
