---
title: A Vanished Bug Is Not a Fixed Bug
slug: a-vanished-bug-is-not-a-fixed-bug
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI declaring victory because the bug stopped reproducing on its own"
---

# A Vanished Bug Is Not a Fixed Bug

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from declaring a bug resolved because it stopped appearing, with no identified cause and no identified fix.

**[Copy-paste ready version](../../install/a-vanished-bug-is-not-a-fixed-bug.md)** — just the instruction block, no explanation.

## The Problem

Mid-investigation, the bug stops reproducing. Maybe the AI made some exploratory edits, maybe it didn't change anything at all — either way, five consecutive runs pass, and the AI announces the issue "appears to be resolved." No cause was identified. No fix was identified. The bug didn't surrender; it went home, the way intermittent bugs do, and it will be back on its own schedule — except now the ticket is closed, the context is gone, and whoever sees it next starts from zero.

A bug that vanishes without explanation is strictly more alarming than one that reproduces reliably, because whatever condition controls it — timing, load, data, environment — is unknown *and* demonstrated to vary. The AI reads disappearance as resolution because absence-of-failure pattern-matches to success, and because "it works now" is a satisfying place to stop. But "I can no longer reproduce it" and "it is fixed" are different claims with different evidence requirements, and only one of them has been met.

The especially insidious version: the bug fades during a session full of exploratory edits, and the AI retroactively credits whichever edit it likes best — manufacturing a fix narrative for a disappearance it doesn't understand.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### A Vanished Bug Is Not a Fixed Bug

NEVER declare a bug resolved because it stopped reproducing. "Fixed" requires an identified cause and a specific change that removes it; "I can't make it happen anymore" is a status report, not a resolution.

A bug that vanishes unexplained is controlled by a condition you haven't found — which means it chooses when to return, and it will.

- When a bug stops reproducing mid-investigation, treat that as a new fact to explain: what changed between the last failing run and the first passing one? (your edits, the data, the time of day, the environment, restarted processes)
- Diff everything between those two runs; if the answer is "nothing I'm aware of," the trigger condition is part of the bug and the investigation is not over
- Never retroactively credit an exploratory edit as "the fix" — to claim an edit fixed it, re-introduce the failure by reverting that edit and confirm the bug returns, then re-apply and confirm it's gone
- If you cannot make the bug come back at all, report honestly: cause unknown, currently not reproducing, here is what I observed, here is what to capture if it recurs (logs, inputs, state) — and propose instrumentation so the next occurrence is diagnosable
- Close as fixed only with the full sentence available: "the cause was X, the change Y removes it, demonstrated by Z"
- "Haven't seen it in a while" is never evidence; intermittent bugs are defined by being intermittent

**Red flags that you're about to violate this:**
- "I've run it ten times and it passes now — looks resolved..."
- "One of my earlier changes must have fixed it..." (which one? prove it)
- "It might have been a transient environment issue..." (might?)
- "I can't reproduce it anymore, so we're good..."
- Writing a fix summary for a session in which no causal fix was identified
- Feeling relief at the disappearance instead of suspicion

---

## Why It Works

1. **It splits two claims the AI conflates.** "Not reproducing" and "fixed" feel identical from inside a passing test run; stating their different evidence requirements makes the gap visible at exactly the moment it's about to be papered over.

2. **It demands the revert-and-return proof.** The retroactive fix narrative — crediting a favorite edit — dies when the standard is "remove the edit, watch the bug return." Either the proof works (real fix, now verified) or it doesn't (narrative exposed).

3. **It treats disappearance as data.** "What changed between the last failure and the first pass?" converts the most discouraging moment in debugging into a concrete diff to investigate, often revealing the trigger condition itself.

4. **It provides the honest off-ramp.** "Cause unknown, here's the instrumentation for next time" is an acceptable deliverable, which removes the incentive to dress up a vanishing as a victory.

## Origin

An intermittent data-corruption bug stopped appearing midway through an assistant's investigation, and the session concluded: "the serialization change I made earlier appears to have resolved the issue." The serialization change was unrelated — the corruption depended on a cache node that had been rotated out that morning by routine maintenance. The bug returned eighteen days later on the replacement node, the closed ticket sent everyone hunting in serialization code, and the actual cause took two more incidents to find because the original disappearance had been explained with fiction.
