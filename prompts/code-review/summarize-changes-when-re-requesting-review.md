---
title: Summarize What Changed When Re-Requesting Review
slug: summarize-changes-when-re-requesting-review
category: code-review
tags: [universal, review, communication]
works_with: all
severity: medium
one_liner: "Stops silent re-review requests that make reviewers re-derive what changed"
---

# Summarize What Changed When Re-Requesting Review

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents hitting "re-request review" with zero explanation, leaving the reviewer to reconstruct what happened since their last pass.

**[Copy-paste ready version](../../install/summarize-changes-when-re-requesting-review.md)** — just the instruction block, no explanation.

## The Problem

Round two of review begins with a notification and nothing else. The reviewer opens the PR to find six new commits with messages like "address feedback" and "fix," plus a handful of scattered thread replies. To do their job, they must now reconstruct: which of my comments were addressed? How? Did anything change that I *didn't* comment on? Was anything pushed back on? The author — the party holding all of this state — shipped none of it.

Assistants skip the round-summary because re-requesting review is a button, and the button doesn't ask for prose. Each individual fix may have gotten a thread reply, but thread replies are scattered across files and collapsed by default; nobody assembles the round-level picture. The model considers its state transmitted because it exists somewhere, in pieces.

The reconstruction cost lands on the most expensive participant. Worse, reviewers who face it repeatedly adopt the rational defense: skim the new commits, trust the resolved checkmarks, approve. The re-review becomes a formality precisely on the PRs that went through the most churn — the ones that needed it most.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Summarize What Changed When Re-Requesting Review

NEVER re-request review without posting a round summary: one comment that tells the reviewer what changed since their last pass, where to look, and what remains open.

You hold the complete state of the revision round; the reviewer holds none of it. Re-requesting without a summary transfers your bookkeeping onto the most expensive person in the loop.

The summary covers four things, briefly:

- **Per comment**: what you did — "Null check: added in `parse()` (commit `c41f2`). Retry suggestion: implemented with backoff instead of fixed interval, see thread. Naming nit: done."
- **Anything changed beyond the comments**: refactors, fixes you found yourself, new code. This is the part the reviewer cannot discover from threads, so it matters most: "Also: extracted `validateHeader()` while fixing the null check — new function, please look."
- **What's still open**: disagreements awaiting their reply, items deferred with their consent, questions you asked.
- **Where to look**: "Changes are in commits `c41f2..e9a01`; everything before that is untouched" — so they can use the range diff instead of re-reading the world.

Keep it tight — a scannable list, not an essay. Five comments addressed identically can be one line. The test: can the reviewer plan their entire second pass from your summary alone?

**Red flags that you're about to violate this:**

- "I replied in every thread, the information is all there..."
- "The commits are self-explanatory if they read them in order..."
- "A summary repeats what the diff already shows..."
- "It's only a small round, they'll figure it out in a minute..."
- "I'll just re-request now and they can ask if anything's unclear..."

---

## Why It Works

1. **It moves bookkeeping to the party that already has it.** The author's marginal cost of writing the round state is near zero; the reviewer's cost of reconstructing it is the largest line item in round two. The rule arbitrages that gap.
2. **The "beyond the comments" section closes the discoverability hole.** Thread replies cover commented code by construction; changes nobody commented on have no thread — the summary is the only channel they can surface through.
3. **The commit-range pointer converts re-review from O(PR) to O(round).** Reviewers re-read only what moved, which keeps second passes real instead of ceremonial.
4. **A summary is a self-audit with a side effect.** Writing "what I did per comment" is exactly the checklist that catches the comment you forgot — before the reviewer does.

## Origin

A reviewer got a bare re-request on a PR they'd reviewed nine days earlier, with eleven new commits on it. Reconstructing the round from thread crumbs took longer than their original review, so they didn't: they checked that their threads showed resolved, skimmed the latest commit, approved. One of the middle commits had rewritten the permissions check "while addressing the session comment" — unprompted, unannounced, and wrong for service accounts. It surfaced three weeks later as a support escalation from the company's largest customer.
