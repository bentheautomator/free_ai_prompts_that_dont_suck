---
title: Fix Blockers Before Nitpicks
slug: fix-blockers-before-nitpicks
category: code-review
tags: [universal, review, prioritization]
works_with: all
severity: medium
one_liner: "Stops review responses that polish nitpicks while blockers sit untouched"
---

# Fix Blockers Before Nitpicks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents treating a reviewer's blocking concerns and trivial nitpicks as an undifferentiated to-do list, worked in whatever order they appear.

**[Copy-paste ready version](../../install/fix-blockers-before-nitpicks.md)** — just the instruction block, no explanation.

## The Problem

The review contains twelve comments: ten naming and formatting nits, one request for a missing test, and one "I think this can double-charge if the webhook retries — needs a look before merge." The assistant works the list top to bottom. Forty minutes later it pushes a commit fixing nine nits and replies to the thread; the double-charge question, comment eleven, is "still in progress." The session ends, or the context fills, or the user steps in — and what got done is the trivia, while the blocker is exactly where it started.

Assistants do this because review comments arrive as a flat list, and a flat list invites sequential processing. Nits are also psychologically attractive work units: each is unambiguous, completable in seconds, and produces a satisfying resolved-thread tick. The blocker requires investigation with an uncertain endpoint. Given a mixed pile, greedy completion eats the easy items first — and any interruption mid-pile means the hard item, the one gating merge, starved.

The reviewer sees motion — commits, replies, resolved threads — and reasonably reads it as progress toward merge. It isn't. The PR is precisely as unmergeable as before the forty minutes started.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fix Blockers Before Nitpicks

ALWAYS triage review comments by severity before acting on any of them, and work blockers first. Comment order in the UI is file order, not importance order.

A review round where ten nits got fixed and the blocker didn't is a failed round, no matter how many threads turned green.

- First pass: classify every comment as blocker (correctness, security, data loss, "needs to happen before merge"), substantive (tests, design concerns, error handling), or nit (naming, style, typos). When the reviewer labeled severity, use their labels; when they didn't, infer — "can this double-charge?" is a blocker regardless of how gently it's phrased.
- Work order: blockers, then substantive, then nits. If a blocker needs investigation, start the investigation before touching a single nit.
- If you might run out of time, budget, or context mid-round, this ordering is what guarantees the remaining work is the cheap kind.
- In your replies, reflect the triage: lead with the blocker's status even if it's "still investigating, here's what I've ruled out." Never let a wall of resolved nit-threads stand in for progress on the thing gating merge.
- Phrasing is not severity. Reviewers soften blockers ("might be worth checking...") and harden nits ("this name is wrong"). Classify by consequence, not tone.

**Red flags that you're about to violate this:**

- "I'll knock out the quick ones first to build momentum..."
- "Let me get the easy threads resolved so the review looks cleaner..."
- "The deadlock question needs a deep dive, I'll save it for last..."
- "Ten of twelve comments addressed is great progress..."
- "The reviewer phrased it as a question, so it's probably optional..."

---

## Why It Works

1. **Triage-before-action breaks greedy sequencing.** The failure requires processing the list in encounter order; a mandatory classification pass makes importance order available before any work starts.
2. **It makes the ordering interruption-proof.** Sessions end and contexts fill at unpredictable points. Blockers-first means any truncation leaves nits stranded instead of the merge-gating item — the rule optimizes the worst case, which is the case that happens.
3. **"Consequence, not tone" corrects a systematic decoder error.** Human reviewers hedge their most serious concerns; a model classifying by phrasing will reliably rank the double-charge question below the naming complaint.
4. **Leading replies with blocker status re-anchors the reviewer's progress read.** Resolved-thread counts are a misleading proxy; the rule replaces the proxy with the actual gating variable.

## Origin

A release-blocking PR got a review with one serious item — "the migration locks the orders table; have you checked how long it holds it?" — and fourteen nits. The assistant spent its session resolving nits and pushed a tidy commit. The migration question got its investigation the next day, after a human noticed it unanswered, and the answer was "eleven minutes at production row counts." Had the nit-polishing commit shipped on schedule, checkout would have been down for all eleven of them.
