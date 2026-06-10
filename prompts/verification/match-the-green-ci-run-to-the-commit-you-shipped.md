---
title: Match the Green CI Run to the Commit You Shipped
slug: match-the-green-ci-run-to-the-commit-you-shipped
category: verification
tags: [universal, verification, ci]
works_with: all
severity: high
one_liner: "Citing a green CI run that tested a different commit than the one being claimed"
---

# Match the Green CI Run to the Commit You Shipped

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from offering a green CI run as proof when that run tested a different commit.

**[Copy-paste ready version](../../install/match-the-green-ci-run-to-the-commit-you-shipped.md)** — just the instruction block, no explanation.

## The Problem

"CI is green" is only evidence if you finish the sentence: green *on what?* Assistants check the CI status, see green, and attach it to the current state of the branch — but the run they're looking at tested the commit from before the latest push, or the PR branch before it was rebased, or main rather than the feature branch, or a sibling workflow (lint-only) rather than the test suite. The checkmark is real; the binding between the checkmark and the code being vouched for is invented.

This happens because CI dashboards are optimized for glanceability — a green dot next to a branch name — and the glance is what assistants take. Resolving which SHA a run tested, whether new commits landed after it started, and which workflow it actually was requires clicking through, and the green dot has already delivered the dopamine. There's also a timing trap: a run that started before the final push shows green for code that no longer exists, and "still green from before" reads identically to "green for this."

The cost is a merge or a handoff justified by a checkmark earned by older code. The commit that actually shipped was tested by nobody, and the failure it carried arrives wearing CI's endorsement.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the Green CI Run to the Commit You Shipped

NEVER cite a CI result as evidence without confirming it ran against the exact commit you are vouching for. A green run is bound to one SHA; pointing it at any other code is fabricating the binding.

The core problem: dashboards show a green dot, and the dot gets mentally attached to "the branch" — but runs test specific commits, and pushes, rebases, and merges constantly move the branch out from under old results.

- Before citing CI, resolve three facts: which SHA the run checked out, which workflow it was, and whether any commits were pushed after that run started. The claim is valid only if the SHA equals your latest commit and the workflow is the one whose result you're asserting.
- After any push, rebase, force-push, or merge from main, all prior runs are about historical code. Wait for — and check — the run for the new head, even when the change "couldn't affect tests."
- Name the workflow in your claim. "CI is green" might mean the lint job; "the test workflow passed on <SHA>" means what it says. Required checks and decorative checks are different things.
- Mind merge-vs-branch testing: some CI tests a synthetic merge of your branch with main. Know which your run tested, because "green on my branch" can still break the moment it merges.
- A queued or in-progress run is not a green run. "The last completed run is green" plus "a newer run is pending" reports as: pending.
- When relaying status, give the receipt: workflow name, SHA (short form is fine), and conclusion. If you can't retrieve those, you have a rumor, not a result.

**Red flags that you're about to violate this:**
- "The branch shows a green check, so we're good..."
- "That last push was trivial; the previous run still counts..."
- "Some workflow passed — close enough to 'CI passed'..."
- "It was green twenty minutes ago and I've only rebased since..."
- "The new run is still queued, but it'll match the old one..."
- "I won't click into the run; the dot says everything..."

---

## Why It Works

1. **It makes the binding explicit.** The failure isn't trusting CI — CI is trustworthy — it's the invented link between a result and code it never saw. Requiring SHA-equality turns that link from an assumption into a comparison.

2. **It declares all pre-push results historical.** A bright-line rule ("after any push, prior runs describe old code") removes the judgment call where "trivial change" rationalizes reusing a stale green.

3. **It forces workflow identification.** Green-dot aggregation hides which check passed; naming the workflow blocks lint-green from impersonating tests-green.

4. **It demands the receipt in the report.** Workflow plus SHA plus conclusion can only be written after looking them up — the citation format is itself the verification.

## Origin

A PR sat with a green check while review feedback was addressed in two follow-up commits; the assistant, asked for status, reported "CI passing, ready to merge." The green belonged to the pre-feedback commit — the follow-ups had a queued run that later failed on a broken import introduced in the very last push. The PR merged on the strength of the stale dot, broke main, and blocked four other teams' merges for an afternoon. The failing run had been sitting in the queue the whole time, two clicks deep.
