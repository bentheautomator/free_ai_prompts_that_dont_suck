---
title: Resync State After User Intervention
slug: resync-state-after-user-intervention
category: agents-and-automation
tags: [universal, agents]
works_with: all
severity: high
one_liner: "Acting on a snapshot of the repo the user changed minutes ago"
---

# Resync State After User Intervention

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from resuming work on its remembered version of the world after the user has changed files, branches, or direction.

**[Copy-paste ready version](../../install/resync-state-after-user-intervention.md)** — just the instruction block, no explanation.

## The Problem

The user pauses the agent, fixes something by hand, maybe pulls a branch or reverts an edit they didn't like, and says "okay, continue." The agent continues — from its memory of the workspace as it was before the pause. It re-applies a change the user just reverted. It edits a function the user already fixed, overwriting their fix with its stale version. It keeps executing a plan whose premise the user's intervention just dissolved. The user intervened to steer; the agent drove on with the old map.

This happens because nothing in the agent's context updates when the world changes — its knowledge of the repo is a stack of snapshots from earlier reads, all still vivid, none marked as expired. A human returning to their desk after someone borrowed it instinctively looks things over. An agent has no such instinct: "continue" reads as "resume from where my context says we were," when after an intervention it actually means "resume from where things now are," and those can differ in exactly the places the user touched — which are exactly the places they care about most.

The bitterest version is the overwrite: the user hand-corrects the agent's work, says continue, and the agent's next edit to that file is built from the pre-correction content, deleting the correction. The user fixed it once, then had to fix the agent re-breaking it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Resync State After User Intervention

ALWAYS re-establish the current state of the workspace before resuming after a user intervention. "Continue" after a pause means continue from where things ARE, not from where your context remembers them being.

The core problem: your knowledge of the repo is a stack of snapshots from earlier reads, and nothing marks them expired when the user changes things. The files most likely to have changed are the ones the user cared enough to touch — which makes stale memory most wrong exactly where precision matters most.

- On resuming after the user paused you, took over, or did anything off-stage: run a quick resync before any edit. Check `git status` and `git diff` for changes you didn't make, confirm the current branch, and re-read any file you're about to modify.
- Treat every file the user touched as the new authority. If their change conflicts with your plan or undoes part of your work, the intervention IS the message: they wanted it that way. Adjust the plan to their change — never adjust their change to your plan.
- Never re-apply anything the user reverted. A reverted edit is a rejected edit. If you believe it was load-bearing, say so and ask: "You reverted X; my plan assumed it because Y. Should I rework the plan?"
- Recheck the plan's premises, not just the files: if the user's intervention fixed the very problem you were mid-way through solving, or changed the approach, the remaining steps may be obsolete. Confirm direction in one line before a long resumed run: "Resuming with X and Y remaining — still right?"
- If the user says they changed something but you can't find it, ask rather than assuming they're mistaken — you may be looking at a stale read.
- The resync is cheap: a status check, a diff, a couple of re-reads. Do it even when you're "sure" nothing relevant changed — the intervention itself is evidence that something did.

**Red flags that you're about to violate this:**
- "Resuming where I left off..."
- "I'll re-apply my change — it seems to have been undone..."
- "I already know what's in that file..."
- "Their edit doesn't match my plan, I'll bring it back in line..."
- "Nothing they did should affect my next steps..."

---

## Why It Works

1. **It marks snapshots as perishable.** The agent's reads don't come with expiry dates; the rule installs one — "any user intervention expires every snapshot" — which converts confident stale memory into a known unknown that triggers re-reading.

2. **It sets precedence between user changes and the plan.** The overwrite disaster happens when the agent treats divergence from its plan as drift to correct. Declaring the user's touch authoritative reverses the arrow: the plan adapts, never the user's change.

3. **It defines reverted as rejected.** Re-applying undone work is the single most trust-destroying move in this family. An explicit semantic — reversion is feedback, not accident — plus an ask-first path for genuine disagreement closes it.

4. **It extends the resync to premises.** Re-reading files but executing an obsolete plan is half a fix; the one-line direction check catches interventions that changed the why, not just the what.

## Origin

An agent was mid-task hardening input validation when the user paused it, simplified two of its already-written validators by hand, and typed "looks good now, keep going." The agent's next edits rebuilt both validators to its original, more elaborate design — from pre-pause file content — erasing the user's simplifications. The user restored their version and continued; the agent overwrote it again while completing "the remaining validators consistently." The third time, the user ended the session and filed the transcript under a name not suitable for a README.
