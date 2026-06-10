---
title: Run a Premortem Before Executing
slug: run-a-premortem-before-executing
category: planning
tags: [universal, planning, risk]
works_with: all
severity: medium
one_liner: "Plans written entirely in the happy-path tense"
---

# Run a Premortem Before Executing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents executing a plan that was never asked "how does this go wrong?"

**[Copy-paste ready version](../../install/run-a-premortem-before-executing.md)** — just the instruction block, no explanation.

## The Problem

Assistant-written plans are written in the happy-path tense. Step 3 says "migrate the data" — not "migrate the data, which will be running against live traffic, while writes continue arriving." Step 5 says "switch the DNS" — not "switch the DNS, after which old clients with cached records will hit the dead endpoint for up to an hour." The plan describes what happens when everything cooperates, because the model generating it is completing the pattern of a plan, and plans-as-a-genre are optimistic documents.

The missing pass is cheap and has a name: the premortem. Before executing, assume the plan failed and write down why. Not vague risk-speak — specific mechanisms: "the backfill collides with live writes," "the feature flag defaults wrong for existing sessions," "two deploys race during the cutover." Most entries take one sentence to mitigate once written down (add a checkpoint, flip the default, lock deploys). Unwritten, each one is a 2am page.

This is not the same as testing, which checks the code. The premortem checks the *plan* — sequencing, rollout, timing, the seams between steps — which is exactly the layer tests can't see and where the worst surprises live.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Run a Premortem Before Executing

ALWAYS run one "how does this fail?" pass over a plan before executing it. Assume the plan failed; write the three most plausible reasons why, as specific mechanisms, and adjust the plan for any you can't accept.

The core problem: generated plans describe the happy path by default, so failure modes that take one sentence to mitigate on paper get discovered live instead.

- After drafting and before executing, list 3-5 concrete failure mechanisms. "Something might break" is not one. "The backfill and live writes race on the same rows" is.
- Probe the seams specifically: what happens *between* steps? Mid-migration state, half-deployed code, the window where old and new coexist.
- Ask what's true in production that isn't true on your machine: traffic, data volume, weird historical rows, concurrent users, other deploys.
- For each mechanism: mitigate it (a step changes), accept it (say so out loud), or escalate it (the user decides). No mechanism just evaporates.
- Spend minutes, not hours. The premortem is one focused pass — if it finds nothing for a trivial change, fine, it cost ninety seconds.

**Red flags that you're about to violate this:**
- "The plan is straightforward, what could go wrong..."
- "I'll handle problems as they come up..."
- "Each step works, so the sequence works..."
- "Edge cases are an implementation detail..."
- "Listing risks feels like padding the plan..."

---

## Why It Works

1. **The prospective-hindsight trick produces specifics.** "What are the risks?" yields boilerplate; "it failed — why?" forces the generator to construct an actual causal story, and causal stories contain fixable details.

2. **It audits the layer tests can't reach.** Tests validate code states; premortems validate transitions — ordering, cutover windows, coexistence of old and new. Most deployment disasters are transition bugs that no unit test could express.

3. **The mitigate/accept/escalate triage closes the loop.** A risk list that doesn't change the plan is decoration. Forcing each item to a disposition is what converts the pass from ritual into engineering.

## Origin

A plan to rename a queue moved consumers first, then producers — each step correct, both verified in staging. The premortem nobody ran would have asked about the gap between the steps: in that window, producers were still writing to the old queue that nothing consumed. Forty minutes of customer events accumulated silently and were never processed, discovered a week later through a reconciliation report. The fix that would have come out of the premortem was one line in the plan: drain and verify the old queue before decommissioning anything.
