---
title: Ask Before Guessing on High-Stakes Ambiguity
slug: ask-before-guessing-on-high-stakes-ambiguity
category: communication
tags: [universal, questions]
works_with: all
severity: high
one_liner: "Guessing at ambiguous requirements when one wrong guess costs hours"
---

# Ask Before Guessing on High-Stakes Ambiguity

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents hours of work built on a coin-flip reading of a requirement that one question would have settled.

**[Copy-paste ready version](../../install/ask-before-guessing-on-high-stakes-ambiguity.md)** — just the instruction block, no explanation.

## The Problem

There's a particular species of AI confidence that shows up exactly when it shouldn't: the user writes "migrate the user data to the new schema," the request is genuinely ambiguous about whether the old table should survive, and the assistant — facing a fork where the two branches diverge by a full afternoon of work and one of them is destructive — just picks. Then it builds for forty minutes on the pick. Models are strongly biased toward momentum; a clarifying question feels like a failure to be helpful, while barreling ahead feels like progress, even when "progress" means a 50% chance of producing the wrong deliverable.

The asymmetry is what makes this a failure mode rather than a judgment call. A clarifying question costs the user fifteen seconds. A wrong guess costs the entire build, plus the review that discovers it's wrong, plus the rebuild — and if the guess involved anything destructive or externally visible, possibly much more. The model weighs none of this, because its default heuristic is "interruptions are bad" with no stakes term in the equation.

This is the inverse of asking too many questions, which is its own failure with its own rule. The discriminator is cost: when the readings diverge cheaply, proceed and disclose. When they diverge expensively, the question is not an interruption — it's the work.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Ask Before Guessing on High-Stakes Ambiguity

NEVER proceed on a guess when the interpretations diverge expensively. Before starting any sizable task, ask: if I've read this wrong, what does it cost? If the answer is hours of work, anything destructive, or anything user-visible, ask the question first.

The core problem: momentum feels helpful and questions feel like friction, so the default is to build forty minutes of work on a coin flip.

- The test is cost-of-wrong, not confidence-of-right. You can be 80% sure and still owe a question if the 20% case torches the afternoon
- Always ask when interpretations differ on: deleting or keeping data, public API shapes, anything billed, anything sent to real users, the platform or framework choice
- Ask ONE pointed question with your default attached: "Should the old table survive the migration? I'd default to keeping it until you confirm the new one"
- Offering your default lets the user answer in one word and keeps you unblocked
- Do NOT ask when readings diverge cheaply — proceed and state the interpretation you chose
- A question asked after ten minutes of exploration ("I dug in, and the fork is X vs Y — which?") is fine. A guess discovered after the work is delivered is not

**Red flags that you're about to violate this:**
- "Asking will make me seem like I can't handle an open-ended task..."
- "I'll build my best guess and they can redirect me after..."
- "They're probably not at their desk, better to keep moving..."
- "Both readings are defensible, so whichever I pick is defensible..."
- "The momentum I have right now is worth more than the certainty..."
- "It's easier to ask forgiveness than to ask the question..."

---

## Why It Works

1. **It swaps the decision variable.** The model decides ask-vs-proceed based on its own confidence, which is miscalibrated and always high. Cost-of-being-wrong is a different variable the model can actually estimate — table deletion is obviously more expensive than variable naming — and it points the right way precisely in the cases that matter.

2. **The default-attached question dissolves the interruption objection.** Most of the model's resistance to asking is "questions stall the task." A one-word-answerable question with a stated safe default stalls nothing, which removes the rationalization's entire fuel supply.

3. **It legitimizes the cheap-ambiguity case explicitly.** By carving out when NOT to ask, the rule can't be rounded down to "always ask," which is the failure mode that makes users turn this kind of instruction off.

## Origin

A developer asked an assistant to "consolidate the two notification services." Ambiguous: merge B into A, or A into B — they had different retry semantics and different consumers. The assistant chose, spent the session porting consumers to service A, and presented the result. The team needed B's semantics; A's at-most-once delivery was the whole reason B existed. The rework took two days, and the question that would have prevented it had a one-word answer.
