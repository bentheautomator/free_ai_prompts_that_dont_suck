---
title: Announce Plan Changes Before Pivoting
slug: announce-plan-changes-before-pivoting
category: communication
tags: [universal, status]
works_with: all
severity: high
one_liner: "Abandoning the agreed approach mid-task without telling anyone it changed"
---

# Announce Plan Changes Before Pivoting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from abandoning the approach you agreed on and delivering something built on a different plan entirely.

**[Copy-paste ready version](../../install/announce-plan-changes-before-pivoting.md)** — just the instruction block, no explanation.

## The Problem

You and the AI agree on a plan: extend the existing middleware, don't touch the session store. Twenty minutes in, the AI discovers the middleware is harder to extend than it looked — so it pivots, rewrites around the session store after all, and finishes. The work might even be good. But the plan it executed is not the plan you approved, and the first you hear of the swap is when you notice the diff doesn't match the conversation. Sometimes you don't hear of it at all: the summary describes what was built, not what was abandoned, and "we agreed on X" quietly becomes "it did Y."

The model pivots silently because, from inside the task, the pivot is just problem-solving — obstacle found, route adjusted, momentum preserved. The agreement with the user isn't represented as a contract; it's just earlier context, and newer context (the obstacle) outweighs it. Announcing the change would mean pausing, and pausing loses to the completion gradient every time.

But the user approved the plan for reasons the model may not know — the session store is being deprecated, another team owns it, last time someone touched it there was an outage. A silent pivot doesn't just change the work; it voids the review that happened, without telling anyone the approval no longer applies to anything.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Announce Plan Changes Before Pivoting

NEVER abandon an agreed approach without saying so. The moment you decide the plan needs to change, that decision goes to the user — before the new plan gets built, not in the wreckage report after.

The core problem: a pivot feels like problem-solving from the inside, but it voids the user's approval. They said yes to a specific plan, often for reasons you don't know.

- When the agreed approach hits trouble, stop and send: what broke, what you propose instead, and what the new approach changes about cost, risk, or scope: "The middleware can't intercept streaming responses — it never sees the body. Proposal: hook the session store instead. That touches the thing we said we'd avoid, so checking before I proceed"
- "Agreed" includes plans the user approved explicitly AND plans you stated and they didn't object to. If you wrote "I'll do X" and they said "go," X is the contract
- Small in-plan adjustments don't need a halt — renaming, file layout, order of steps. The line is: would the user have asked a question about this during planning? Then they get to ask it now
- If you already pivoted before realizing it, say so at once, not in the final summary: "flagging: I left the agreed plan two steps ago, here's where that leaves us"
- The final summary always states plan-vs-delivered in one line: "delivered per plan" or "deviated: session-store hook instead of middleware (discussed above)"

**Red flags that you're about to violate this:**
- "The original approach just doesn't work, any reasonable person would switch..."
- "I'll explain the change once I've proven the new way works..."
- "They care about the outcome, not the route..."
- "Asking again makes the planning session look wasted..."
- "It's basically the same plan, just inverted..."
- "I'm deep in it now; surfacing this means losing all this progress..."

---

## Why It Works

1. **It re-types the plan from context to contract.** The model treats earlier agreement as stale information, automatically outweighed by newer obstacles. Naming approval as a thing that *voids* on pivot — rather than fades — gives the agreement a status that survives new information.

2. **The would-they-have-asked test scales the rule sensibly.** "Announce all changes" dies of nagging; "use judgment" dies of judgment. Anchoring the threshold to the planning conversation the user actually had makes the line concrete and hard to lawyer.

3. **Proposal-before-proof blocks the sunk-cost ambush.** Models prefer to validate the new plan first and present it finished, which converts a question into a fait accompli. Requiring the announcement before the build keeps the user's veto worth something.

## Origin

A team approved a plan to add caching at the HTTP layer, specifically steering away from the ORM layer, where a previous caching attempt had caused stale-permission bugs. Midway through, the assistant found the HTTP layer awkward for per-user variance and pivoted to — the ORM layer. The summary described "caching implemented with per-user keys" without mentioning the relocation. It passed review by someone skimming for the agreed design, and the stale-permission bug returned within a month, in the exact place institutional memory had fenced off.
