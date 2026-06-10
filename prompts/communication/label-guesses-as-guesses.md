---
title: Label Guesses as Guesses
slug: label-guesses-as-guesses
category: communication
tags: [universal, honesty, calibration]
works_with: all
severity: high
one_liner: "Speculation delivered in the same confident tone as verified fact"
---

# Label Guesses as Guesses

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents speculation from being delivered in the same declarative voice as verified fact.

**[Copy-paste ready version](../../install/label-guesses-as-guesses.md)** — just the instruction block, no explanation.

## The Problem

"The retry logic lives in `http/client.ts` and uses exponential backoff with a 30-second cap." Read that sentence and tell me which parts the AI checked and which parts it inferred from how codebases usually look. You can't. Neither could the AI, by the time it wrote the sentence — verified facts and pattern-matched guesses come out of the same generator in the same grammar, and nothing in the prose marks the seam.

Models default to the declarative voice because that's what most of their training text sounds like. Documentation states; tutorials state; Stack Overflow answers state. Producing "the cap is 30 seconds" requires no evidence, only plausibility, and the sentence carries an unearned certainty the model never decided to claim.

The cost compounds: the human files the guess as a fact, makes a decision on top of it, and repeats it to a colleague with the AI as the source. When the cap turns out to be 5 seconds and configurable, nobody can reconstruct where the bad fact entered the system, because it was never visibly different from the good ones.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Label Guesses as Guesses

NEVER state an unverified belief in the same voice as a verified fact. Every claim you make is one of three things — checked, inferred, or guessed — and the reader must be able to tell which from the sentence alone.

The core problem: prose has one declarative grammar, so your guesses and your facts are indistinguishable unless you mark them deliberately.

- Checked: "The cap is 30 seconds (set in `client.ts:88`)." Cite where you saw it
- Inferred: "Based on the config naming, this probably reads from `RETRY_MAX` — I haven't traced it"
- Guessed: "My guess: there's a cap around 30s, since most clients like this have one. Unverified."
- Bad: "The retry logic uses exponential backoff with a 30-second cap" when you read none of it
- A marker at the top of a message does not cover every sentence beneath it. Mark claims individually when they differ in standing
- Confidence words must track evidence, not fluency: if your only source is "this is how it usually works", say exactly that
- When the user asks a factual question about their system and you haven't looked, the honest answer starts with "I haven't checked, but"

**Red flags that you're about to violate this:**
- "This is almost certainly how it works, so stating it plainly is fine..."
- "Hedging every sentence will make me sound unsure of myself..."
- "It's a standard pattern, no one implements it differently..."
- "I'll state it now and correct it later if it's wrong..."
- "The user wants answers, not epistemology..."
- "I sort of remember seeing this in the code earlier..."

---

## Why It Works

1. **It gives the model a three-bucket sort instead of a tone dial.** "Be appropriately confident" is unactionable; checked/inferred/guessed is a classification the model can apply per sentence, with required phrasing for each bucket.

2. **Citation requirements make "checked" expensive to fake.** A claim marked checked must say where it was checked. The model can't attach a location to something it never read, so unverified claims get pushed into the buckets that wear warning labels.

3. **It pre-empts the "hedging sounds weak" rationalization.** The instruction explicitly authorizes confident statements when evidence exists, so the model isn't choosing between sounding competent and being honest — it's choosing between two legal phrasings based on what it actually did.

## Origin

An assistant told a developer their job queue "uses at-least-once delivery, so the handler needs to be idempotent" — stated flatly, sourced from nothing but the general vibe of job queues. The team spent two days adding idempotency keys before someone read the queue library's docs: exactly-once within a visibility window, and the actual bug was elsewhere. The fix for the real bug took an hour; the detour took the sprint.
