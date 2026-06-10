---
title: State Your Plan Assumptions Explicitly
slug: state-your-plan-assumptions-explicitly
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "Plans that hide their load-bearing guesses where no reviewer can challenge them"
---

# State Your Plan Assumptions Explicitly

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents plans whose load-bearing assumptions are invisible to the person approving them.

**[Copy-paste ready version](../../install/state-your-plan-assumptions-explicitly.md)** — just the instruction block, no explanation.

## The Problem

Every plan rests on assumptions — about traffic, about data shapes, about what other systems do, about what the user values. The plan the assistant presents shows the *steps*, but the assumptions stay in the substrate: step 4 says "process the queue nightly" and nowhere says "...because I'm assuming same-day isn't required." The user reviews the steps, the steps look fine, approved. The assumption — wrong, as it happens — sailed through review untouched, because it was never on the page to be challenged.

This is what makes plan review weaker than it looks. Reviewers can only push back on what's written, and assistants write conclusions, not premises. The user knows things the assistant doesn't — that the data has duplicate IDs, that traffic spikes 50x during enrollment week, that the "internal" endpoint has a partner consuming it — but that knowledge only activates when it collides with a stated premise. "I'm assuming IDs are unique" gets an instant correction. A plan silently built on unique IDs gets approved, built, and corrected by production.

The fix is a disclosure line: plans carry a short "Assuming:" list of the premises that, if wrong, would change the plan. Three to five items, one line each. It converts the reviewer from an admirer of steps into a checker of premises — which is the review that was actually needed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### State Your Plan Assumptions Explicitly

ALWAYS attach the load-bearing assumptions to the plan, in their own labeled list. A reviewer can only correct premises they can see; a plan that shows conclusions while hiding premises gets its steps admired and its actual bets unexamined.

The core problem: the user holds facts that would kill bad assumptions on contact — but that knowledge only activates against a *stated* premise, and assistants state steps, not premises.

- End every non-trivial plan with "Assuming:" and 3-5 one-line premises that, if wrong, would change the plan. Volume, data shape, what other systems consume, what the user values, what's allowed to change.
- Pick the load-bearing ones, not the safe ones. "Assuming the repo uses git" is filler; "assuming order IDs are unique across regions" is a real bet someone can falsify in five seconds.
- Phrase them falsifiably: "assuming nightly batch is acceptable (no same-day requirement)" — so the user's "actually, finance needs same-day" has a sentence to collide with.
- Distinguish from open questions: an assumption is what you'll proceed on without an answer; a question blocks. If a premise is too risky to proceed on, promote it to a question.
- When an assumption gets corrected, treat it as the review working — re-derive the affected steps before continuing, and say which ones changed.

**Red flags that you're about to violate this:**
- "The plan speaks for itself..."
- "These assumptions are obviously fine, listing them is noise..."
- "I'll mention it if it becomes a problem..." (it becomes a problem in production)
- "The user approved the plan, so they approved everything under it..." (they approved what they could see)
- "Adding caveats makes the plan look weak..." (hidden bets make it actually weak)

---

## Why It Works

1. **It activates the user's private knowledge.** The user often holds the exact fact that falsifies a premise, but recognition is collision-driven: the fact surfaces when it meets a stated claim. The "Assuming:" list manufactures the collisions.

2. **It makes review adversarial where it counts.** Steps are conclusions; reviewing them tests coherence, not truth. Premises are where plans are actually wrong, and they can only be attacked when separated out and written down.

3. **It creates an audit trail for failures.** When something breaks later, a stated assumption list shows exactly which bet failed and that it was disclosed — turning "why did nobody think of this" into "we bet on X knowingly," which is both fairer and faster to fix.

## Origin

A caching plan was approved on the strength of its steps — clean invalidation design, sensible TTLs. Unwritten anywhere: the premise that product prices changed at most daily, which had shaped every TTL in the document. The user, who knew about flash sales, would have killed that premise in one sentence had it appeared on the page. Instead the cache served stale flash-sale prices on its first big weekend, and the postmortem's root cause was, verbatim, "an assumption nobody knew the plan was making."
