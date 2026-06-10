---
title: Hold PR Scope Steady During Review
slug: hold-pr-scope-steady-during-review
category: code-review
tags: [universal, review, scope]
works_with: all
severity: medium
one_liner: "Stops PRs from growing new features and refactors mid-review"
---

# Hold PR Scope Steady During Review

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a PR's scope from expanding round over round during review until the reviewed thing no longer resembles the opened thing.

**[Copy-paste ready version](../../install/hold-pr-scope-steady-during-review.md)** — just the instruction block, no explanation.

## The Problem

The PR opens at 200 lines: add rate limiting to one endpoint. Round one of review goes fine. While addressing it, the assistant notices the limiter would be "more reusable as middleware" — round two arrives at 450 lines. A reviewer comment about config sparks a small config-system refactor — round three, 700 lines, now touching nine files and two unrelated subsystems. Each addition was locally sensible. The sum is a PR that nobody reviewed as a whole: round-one approval covered a fifth of what's now on the branch, and the reviewer is rationally tempted to stop reading and just approve to end it.

Review-time scope creep is distinct from coding-time scope creep because review *feeds* it: every reviewer comment is a fresh prompt, every revision pass re-exposes the code to an agent whose default response to seeing improvable code is improving it. The PR functions as an open transaction the assistant keeps appending to, and the review cycle — which exists to converge — becomes the mechanism that prevents convergence.

The end state is the worst of both worlds: a mega-PR with the review coverage of a small one, plus a reviewer who has re-read the same growing diff four times and is now approving from fatigue.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Hold PR Scope Steady During Review

Once a PR is under review, its scope is FROZEN. Review rounds may only shrink the delta between the code and the reviewer's requests — never grow the PR's mission.

Review is a convergence process. Every scope addition resets convergence and dilutes the review already performed.

- Changes allowed during review: fixes for reviewer comments, bugs found in the PR's existing code, and mechanical necessities (conflict resolution, CI fixes). That's the whole list.
- Improvements you notice while revising — refactors, generalizations, adjacent cleanups, "while I'm in this file" — go to a list in the PR description ("Follow-ups") or a new issue. Not to the branch.
- A reviewer comment that *suggests* expansion ("this could be middleware eventually") is an invitation to discuss, not a work order. Reply with "agreed — follow-up PR?" and let them choose. If they explicitly want it in this PR, that's a human decision and it goes in.
- If addressing a comment properly genuinely requires expansion (the fix doesn't work without restructuring), say so in the thread *before* doing it, with the size estimate: "Fixing this correctly means touching the config loader, roughly +200 lines. In this PR or a precursor PR?"
- Watch the trend line: if the diff is bigger after each review round, the process is diverging. Stop and split.

**Red flags that you're about to violate this:**

- "While I'm fixing this comment, that nearby function could be cleaner too..."
- "Making it generic now saves a follow-up PR later..."
- "The reviewer hinted they'd like this, I'll just build it..."
- "It's already at 500 lines, another 100 won't change much..."
- "Splitting it out means another review cycle, faster to include it here..."
- "This refactor makes the requested fix more elegant..."

---

## Why It Works

1. **The frozen-scope frame gives the model a default of "no."** Without it, each addition is evaluated on its own merits, and each addition has merits. The freeze makes the burden of proof point the other way.
2. **The allowed-changes list is short enough to check against.** Three categories; everything else has a designated destination (follow-up list) rather than just a prohibition, so noticing improvements still produces value — somewhere harmless.
3. **It distinguishes reviewer musing from reviewer instruction.** A large share of mid-review expansion launders itself as "the reviewer wanted it." Requiring an explicit confirmation converts hints back into the discussions they were.
4. **The trend-line check catches divergence as a measurement.** "Diff grew each round" is an objective signal the model can compute, unlike "scope feels big," which it demonstrably can't.

## Origin

A PR to add a health-check endpoint entered review at 90 lines and merged six rounds later at 1,100, having absorbed a logging refactor, a new metrics abstraction, and the beginnings of a service framework, each prompted by an offhand reviewer remark. The final approval comment was a single word from a reviewer who had given up. The metrics abstraction — never actually reviewed by anyone — double-counted requests, and the team spent a week trusting dashboards that were optimistic by a factor of two.
