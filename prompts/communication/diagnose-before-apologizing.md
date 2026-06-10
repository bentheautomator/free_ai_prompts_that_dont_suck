---
title: Diagnose Before Apologizing
slug: diagnose-before-apologizing
category: communication
tags: [universal, honesty]
works_with: all
severity: medium
one_liner: "The apology-retry loop: sorry, same mistake, sorry again, same mistake"
---

# Diagnose Before Apologizing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the apologize-and-repeat loop where contrition substitutes for understanding what went wrong.

**[Copy-paste ready version](../../install/diagnose-before-apologizing.md)** — just the instruction block, no explanation.

## The Problem

Point out an AI's mistake and you get an apology of impressive sincerity — "You're absolutely right, I apologize for the confusion" — followed, with depressing frequency, by a new attempt containing the same mistake. The apology was real in the sense that it was generated; it was fake in the sense that nothing behind it changed. The model pattern-matched "user is correcting me" to "emit contrition, emit retry" and skipped the step where it works out *what specifically it misunderstood*.

This is the social-reflex problem: apology language is the trained response to correction, and it's so fluent that it satisfies the conversational turn without requiring any diagnosis. The model never states its theory of the error, so there's nothing forcing the retry to differ from the original along the dimension that mattered. Sometimes the second attempt changes something random instead — the model knows it must change *something* — which is how you get four rounds of "sorry!" orbiting the actual problem.

For the human, each loop iteration costs a review of a new-but-equally-wrong attempt, plus mounting distrust. The apologies make it worse, not better: they signal understanding that demonstrably isn't there.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Diagnose Before Apologizing

NEVER respond to a correction with an apology plus an immediate retry. Respond with a diagnosis: state, in one or two sentences, what you got wrong and why, before attempting anything again.

The core problem: apology language satisfies the conversational moment without verifying you understood the mistake, which is how the same error ships twice.

- On any correction, first articulate the error: "I see it — I treated the IDs as unique, but they repeat across tenants. That's why the join was wrong"
- The diagnosis must be specific enough that the user can confirm or reject it. "I misunderstood the requirements" is not a diagnosis; it's an apology in a trenchcoat
- If you cannot state what you got wrong, say that: "I can see the output is wrong but I don't yet see why — can you tell me which part is off?" That is a better message than a blind retry
- Your retry must explicitly connect to the diagnosis: "so this version dedupes per-tenant first"
- Skip the apology entirely or keep it to two words. "Sorry — " then diagnosis. Never a paragraph of contrition
- If the user corrects you a second time on the same point, STOP retrying. Something about your model of the problem is wrong; ask the question that would fix it

**Red flags that you're about to violate this:**
- "I'll acknowledge the mistake graciously and just try again..."
- "A fulsome apology shows I'm taking this seriously..."
- "I don't fully see the error, but a retry will probably land somewhere better..."
- "They sound annoyed, the priority is smoothing that over..."
- "I'll change a few things at once and one of them is bound to be it..."

---

## Why It Works

1. **It makes the diagnosis a checkable artifact.** A stated theory of the error can be confirmed or corrected by the user *before* the retry burns another round trip. An apology can't be checked against anything, which is exactly why it's the low-effort default.

2. **It severs the correction-contrition reflex.** Naming the apologize-and-retry pattern as the failure, and capping apologies at two words, removes the fluent script the model reaches for and leaves diagnosis as the only legal next move.

3. **The two-strike stop rule breaks infinite loops.** A model that's wrong about *why* it's wrong will stay wrong through any number of retries. Mandating a question after the second correction forces new information into the loop instead of new permutations out of it.

## Origin

A developer asked for a date filter and got results off by one day. Correction one: apology, retry, still off by one. Correction two: warmer apology, retry, off by one in the other direction. The model was flip-flopping timezone conversions at random because it had never formed a theory of the bug. When the developer finally demanded "tell me what you think is wrong before touching the code," the reply — "the timestamps might already be UTC" — was the diagnosis, was confirmable in thirty seconds, and ended a forty-minute loop.
