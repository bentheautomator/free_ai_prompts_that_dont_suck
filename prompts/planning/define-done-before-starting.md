---
title: Define Done Before Starting
slug: define-done-before-starting
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "Tasks that end when the assistant feels finished, not when anything is verified"
---

# Define Done Before Starting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents starting work whose endpoint is a feeling instead of a checkable condition.

**[Copy-paste ready version](../../install/define-done-before-starting.md)** — just the instruction block, no explanation.

## The Problem

Most tasks begin without anyone saying what finished looks like. The assistant works until the work feels complete — code written, build green, narration wrapped up with "the feature is now implemented" — and stops. Whether the user can actually do the thing they asked for was never the stopping condition, because no stopping condition was ever set. "Done" got decided retroactively, by the person with the strongest incentive to declare it.

The damage runs in both directions. Undershoot: the upload feature "works" but was never tried with a real file, and the missing content-type handling surfaces as the user's problem. Overshoot: with no defined endpoint, the task has no edge, so polishing continues into territory nobody asked for — and each extra hour carries risk without a requirement behind it. Both failures share one root: the finish line was drawn after the race.

A done definition is two or three checkable sentences written before the first edit: what command runs, what behavior is observable, what case must work. It costs a minute. It converts "I believe this is complete" into "these three things are true," and only one of those statements can be wrong quietly.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Define Done Before Starting

NEVER start a task without writing down what "done" means: 2-3 conditions that are checkable by observation, not by confidence. The definition comes before the first edit, while it's still honest — not after, when it's a press release.

The core problem: without a pre-stated endpoint, "done" gets decided by feel at the moment of stopping, which produces both unverified undershoot and unrequested overshoot.

- Before starting, state the done conditions: "done means: a user can upload a 10MB PDF and see it listed; the existing image path still works; `make test` passes."
- Each condition must be observable — a command, a behavior at a URL, a test. "The code is cleaner" and "uploads are handled properly" are moods, not conditions.
- Derive the conditions from the request, then confirm them if there's any doubt. The done definition is also a cheap final check that you understood the task.
- At the end, walk the list and verify each condition actually holds — run the command, perform the behavior. Then report against it: "Done per the stated conditions: 1 yes, 2 yes, 3 yes."
- When you hit the definition, stop. Improvements beyond it are proposals for the user, not silent extensions of the task.

**Red flags that you're about to violate this:**
- "I'll know it's done when I see it..."
- "The implementation is complete" (was that the request, or the requirement?)
- "It compiles and the logic looks right, so it's finished..."
- "While everything's loaded in my head, I'll also improve..." (the task has no edge because you didn't draw one)
- "Defining done is obvious for a task this simple..." (then it'll take ten seconds)

---

## Why It Works

1. **It moves the definition to the honest moment.** Before work starts, "done" is defined by the requirement; after, it's defined by whatever happens to be true of the work. Same words, opposite information flow.

2. **Observable conditions can fail.** "Feels complete" cannot be wrong out loud; "uploading a 10MB PDF shows it in the list" can. Verification only exists where failure is expressible.

3. **It gives the task an edge.** Overshoot isn't stopped by discipline, it's stopped by geometry — a defined boundary makes "beyond the boundary" a visible category that requires a proposal rather than momentum.

4. **It doubles as a requirement check.** A done definition the user disagrees with is a misunderstanding caught at minute one instead of hour six.

## Origin

A "add password reset" task ended with the assistant's summary: implementation complete, emails wired, tokens expiring correctly. The user tried it the next day; the reset link 404'd because the frontend route was never added — resetting passwords wasn't in the verified path, only *sending the email* was. A done definition written up front ("a user who forgot their password can set a new one and log in with it") would have made the missing route unmissable, because the condition would have failed the moment anyone walked it.
