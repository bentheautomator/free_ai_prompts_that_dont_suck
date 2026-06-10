---
title: Tackle the Riskiest Unknown First
slug: tackle-the-riskiest-unknown-first
category: planning
tags: [universal, planning, risk]
works_with: all
severity: high
one_liner: "Discovering on day three that the whole approach hinged on a false premise"
---

# Tackle the Riskiest Unknown First

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents executing a plan whose viability rests on an unverified assumption that could have been checked in five minutes.

**[Copy-paste ready version](../../install/tackle-the-riskiest-unknown-first.md)** — just the instruction block, no explanation.

## The Problem

Most plans contain one assumption that, if false, kills the whole approach: "the library supports streaming," "the webhook fires on updates too," "we can read that table from this service." Assistants write these assumptions into step 4 of the plan and then start cheerfully executing steps 1 through 3 — the steps that only matter if step 4 works.

This is planning by optimism. The assistant treats every step as equally likely to succeed because, in its plan document, every step is just a line of text. But the steps are not equal: three of them are typing, and one of them is a bet. Rational sequencing puts the bet first, because losing the bet early costs five minutes and losing it late costs everything built on top of it.

The fix is not more planning. It's ordering the plan by uncertainty: identify the assumption most likely to be wrong with the worst consequences, and convert it from assumption to fact before writing code that depends on it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Tackle the Riskiest Unknown First

NEVER begin executing a plan until you have named its riskiest unknown and either verified it or scheduled it as step one. An unknown is risky when it's both plausible-to-be-wrong and fatal-to-the-approach-if-wrong.

The core problem: in a written plan every step looks equally solid, but usually one step is a bet and the rest are typing. Doing the typing first means losing the bet at maximum cost.

- After drafting a plan, ask: "Which step, if it fails, invalidates the others?" That step — or a cheap test of it — moves to the front.
- Verify by the cheapest sufficient means: read the library source, run a ten-line script, check the docs for the exact method, query the schema. Minutes, not hours.
- Distinguish unknowns from difficulties. A hard-but-certain step can wait; an easy-but-uncertain step that everything depends on cannot.
- If the unknown can't be verified cheaply (needs prod access, needs an answer from the user), say so explicitly and don't build dependent work on it in the meantime.
- One sentence in your plan output: "Riskiest assumption: X. Verified by: Y." If you can't fill that in, you haven't found it yet.

**Red flags that you're about to violate this:**
- "I'm fairly sure the library handles that, I'll confirm when I get there..."
- "Steps 1-3 are useful regardless..." (are they?)
- "The docs probably cover this case..."
- "I'll build the easy parts while I think about the hard question..."
- "Worst case I'll adjust later..." (worst case you'll rewrite)

---

## Why It Works

1. **It prices uncertainty into the ordering.** Expected cost of a plan is dominated by where its failure points sit. The same steps in risk-first order have a fraction of the expected waste.

2. **It forces the bet to be named.** "Riskiest assumption: X" is a one-sentence artifact that's either fillable or not. Plans without it haven't been examined, only written.

3. **It distinguishes verification from execution.** A ten-line probe script answers the question without committing to the approach. Assistants skip verification because it doesn't produce deliverable code — naming it as step one makes it legitimate work.

## Origin

A plan to add real-time sync hinged on the vendor SDK's change-feed API. The assistant built the sync engine, conflict resolution, and retry logic over two sessions, then discovered in integration that the change feed was only available on a higher pricing tier — a fact on the first page of the SDK's pricing docs. The entire architecture moved to polling, and most of the conflict-resolution work, designed around feed ordering guarantees, was discarded.
