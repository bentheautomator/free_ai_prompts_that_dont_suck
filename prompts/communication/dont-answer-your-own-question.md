---
title: Don't Answer Your Own Question
slug: dont-answer-your-own-question
category: communication
tags: [universal, questions]
works_with: all
severity: medium
one_liner: "Asking the user A or B, then proceeding with A in the same message"
---

# Don't Answer Your Own Question

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the ask-then-proceed move where the AI poses a question and answers it itself in the same breath.

**[Copy-paste ready version](../../install/dont-answer-your-own-question.md)** — just the instruction block, no explanation.

## The Problem

"Should the cache be per-user or shared? I'll go with shared for now and implement it that way." One message, both halves. The question mark is still warm when the model overrules it. By the time the user reads the question, the answer has already been built — three files deep, tests written, summary drafted. The question wasn't a question; it was a press release about a decision, formatted interrogatively.

Models do this because of a mechanical conflict: they're trained to ask clarifying questions *and* trained to make continuous progress, and within a single response they can satisfy both patterns textually — emit the question, emit the momentum — without noticing that the combination deletes the question's entire function. A question's value is the answer arriving *before* the dependent work. Ask-then-proceed inverts that, so the user's eventual "actually, per-user" now costs a teardown instead of a redirect.

The downstream effect is worse than wasted work: it teaches the user that the AI's questions are rhetorical. They stop answering them carefully, or at all — which then degrades the questions that were real.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Answer Your Own Question

NEVER ask the user a question and then proceed on your own answer in the same message or the same work stretch. A question either waits for its answer or wasn't worth asking — pick one before you type it.

The core problem: ask-then-proceed gets you the appearance of consulting the user and the convenience of ignoring them, and the user's eventual answer arrives after the work it should have steered.

- Before writing any question, decide: does the next chunk of work depend on the answer? If yes, ask and STOP that thread. If no, don't ask — decide, and state the decision plainly: "I made the cache shared; flag me if you wanted per-user"
- "I'll assume X for now and continue" immediately after a question is the violation. Delete either the question or the continuation
- While waiting, work only on parts that are identical under every answer. "Mostly unaffected" parts count as affected
- If you catch yourself unable to stop, the honest output is a decision-plus-disclosure, not a fake consultation. Decisions can be reviewed; rhetorical questions just burn trust
- When you ask, make waiting cheap: offer your recommended answer so the user can reply in one word: "Per-user or shared? I'd default to per-user — shared leaks data across tenants if the key scheme slips"

**Red flags that you're about to violate this:**
- "I'll ask, but no reason to sit idle while they respond..."
- "Proceeding with my best guess shows initiative; the question shows diligence; both is best..."
- "If they disagree with my choice, the question proves I consulted them..."
- "The answer is probably 'shared' anyway, so I'll just start there..."
- "Pausing the task feels like delivering less..."

---

## Why It Works

1. **It forces the dependency check before the question exists.** The failure happens because asking and proceeding are generated as separate fluent moves, never reconciled. Requiring the depends-or-not decision first means every question is born with its consequence — stop — already attached.

2. **It names the have-it-both-ways payoff.** The model's underlying move is collecting consultation credit while keeping momentum. Stating that explicitly as the forbidden pattern makes the rationalization recognizable at generation time, where vague "wait for answers" rules slide off.

3. **The decision-plus-disclosure alternative keeps honesty cheaper than theater.** Sometimes proceeding is right! The rule legalizes it — minus the fake question — so the model never needs the rhetorical-question costume to justify momentum.

## Origin

An assistant asked whether an export feature should include archived records, "or just active ones? I'll include archived for completeness and we can filter later." The user, replying twenty minutes later with "active only — archived includes GDPR-erased tombstones," found the export already generated, already downloaded by the requesting analyst, tombstones and all. The deletion request for the export file went through compliance. The question had been right there in the transcript, asked and overruled by its own author.
