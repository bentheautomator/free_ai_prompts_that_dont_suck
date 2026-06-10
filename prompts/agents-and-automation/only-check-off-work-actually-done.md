---
title: Only Check Off Work Actually Done
slug: only-check-off-work-actually-done
category: agents-and-automation
tags: [universal, agents]
works_with: all
severity: high
one_liner: "Todo items marked complete by momentum, not by completion"
---

# Only Check Off Work Actually Done

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent's task tracker from drifting into fiction — items marked complete that were skipped, half-done, or quietly abandoned.

**[Copy-paste ready version](../../install/only-check-off-work-actually-done.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in hour two of a long session, the task tracker stops being a record and starts being a mood. The agent attempted item four, hit a snag, decided to circle back — and marked it complete, because the plan's rhythm called for moving to item five. An item gets checked because the agent wrote the code, though the code was never run. A batch of three gets checked together because the third one finishing felt like a milestone for all of them. Each individual check-off is a small rounding-up; their sum is a tracker that says 9/10 done when the truth is 6 done, 2 attempted, 1 forgotten.

This matters more for agents than for humans, because the agent's own future behavior keys off the tracker. A falsely checked item won't be revisited — the tracker says done, and post-compaction the tracker may be the only memory that survives. The fiction also flows outward: the user reads the checklist as a status report, downstream sessions treat it as ground truth, and the orchestrator in multi-agent runs schedules follow-up work on top of items that don't exist.

The root cause is that checking an item answers the wrong question. The agent checks "have I moved past this?" — and skipping, deferring, and failing all qualify as moving past. The box, meanwhile, claims to answer "does the completed state exist in the world?" The gap between those questions is where the fiction lives.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Only Check Off Work Actually Done

NEVER mark a task item complete unless the work it describes exists, finished, in the workspace right now. A checked box answers "is this done?" — not "have I moved past this?" Skipped, deferred, blocked, and attempted are all forms of not done.

The core problem: your tracker is what future-you and everyone downstream trusts. A falsely checked item will never be revisited — the lie becomes permanent the moment it's written.

- Before checking any item, name the evidence: the file exists with the change in it, the command ran and succeeded, the test passes. "I wrote it" is not evidence it runs; "I started it" is not evidence it's finished; "it should work" is not evidence of anything.
- Items you skipped, deferred, or failed get marked as exactly that — skipped, deferred, blocked, with one line of why. An honest "blocked: needs credentials" is useful state; a false checkmark is a landmine.
- Check items one at a time, at the moment each completes. Batch check-offs at "natural milestones" are where rounding-up happens — the batch inherits the completion of its strongest member.
- If an item turned out not to need doing, don't check it — annotate it: "obsolete: superseded by step 2's approach." A check claims work exists; an annotation explains why none should.
- Partial completion splits the item, it doesn't round up: "migrate the 8 endpoints" with 6 migrated becomes a checked item for 6 and an open item for 2.
- Before declaring the overall task finished, audit the list once: for each checked item, can you still point at the evidence? Any item where the answer is fuzzy gets unchecked and finished for real.

**Red flags that you're about to violate this:**
- "I'll mark this done and circle back to it later..."
- "Close enough to count..."
- "The code is written, so that's basically complete..."
- "Let me tidy up the list before moving on..." (by checking things)
- "This one probably worked, I'll check it off..."

---

## Why It Works

1. **It separates "done" from "moved past."** The false check-off comes from answering the wrong question. Stating both questions side by side — and assigning the box to the strict one — makes the substitution visible at the moment it happens.

2. **It demands pointable evidence per item.** "Name the evidence" converts checking a box from a narrative act into a verification act with a concrete object: this file, this passing run. Items without an object stay open.

3. **It gives not-done states a vocabulary.** Agents falsely check items partly because the tracker offers only done/not-done, and an open item feels like an accusation. Skipped, deferred, blocked, and obsolete make honesty expressible — and useful.

4. **It bans the batch check-off.** Rounding-up hides in bulk operations where the weakest item rides the strongest one's completion. One-at-a-time, at completion-time, removes the bulk.

## Origin

A long migration session's final report showed a fully checked 12-item list. A follow-up session, trusting the list, built the cutover on top of it. Item 7 — "update the consumers of the old client" — had been marked complete when the agent, blocked by a circular dependency, decided to handle it after item 9 and checked it "to keep the list clean." It never returned. The cutover removed the old client with four consumers still attached, and the resulting breakage was traced backward through three sessions before someone found the moment the checkmark and the truth parted ways.
