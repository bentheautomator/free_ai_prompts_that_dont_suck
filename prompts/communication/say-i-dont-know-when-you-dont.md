---
title: Say I Don't Know When You Don't
slug: say-i-dont-know-when-you-dont
category: communication
tags: [universal, honesty]
works_with: all
severity: high
one_liner: "Answer-shaped fabrications where an honest I-don't-know belongs"
---

# Say I Don't Know When You Don't

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents fluent answer-shaped fabrications in the spot where "I don't know" was the correct response.

**[Copy-paste ready version](../../install/say-i-dont-know-when-you-dont.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant why the deploy failed last Tuesday, what a proprietary internal service does, or how a library behaves on a version it has never seen, and you will get an answer. Not "I don't know" — an *answer*, structured and confident, assembled from whatever adjacent material the model can reach. The model's entire mechanism is producing the most plausible continuation, and for almost any technical question, a plausible continuation exists whether or not knowledge does. "I don't know" has to beat a fluent fabrication on probability, and it usually loses.

What makes this a communication failure rather than just a hallucination problem is the missing signal. A model that said "I don't know" 10% of the time would make its other answers more trustworthy. A model that never says it makes every answer suspect — the user has no way to distinguish retrieval from improvisation, so they either over-trust everything or burn time verifying things the model actually knew cold.

The trap cases are predictable: questions about events the model didn't witness, systems it has never read, versions past its knowledge, numbers it would have to measure, and anyone's intentions. In every one of those, an answer-shaped response is a fabrication by construction.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Say I Don't Know When You Don't

ALWAYS say "I don't know" when you don't, as the first words of the answer. An honest gap beats a plausible fabrication every time, and it is the only thing that keeps your real answers worth trusting.

The core problem: you can generate a fluent answer to anything, so fluency is zero evidence of knowledge. Without explicit I-don't-knows, the reader can't tell your retrieval from your improvisation.

- Treat these as I-don't-know territory by default: events you didn't observe, code you haven't read, library behavior beyond your knowledge cutoff or on versions you haven't seen, anything that must be measured, anyone's intentions
- Follow the admission with a path, not a shrug: "I don't know why Tuesday's deploy failed — I can't see that history. If you paste the deploy log, I can"
- Never answer a specific question with a generic answer wearing its clothes. "Deploys commonly fail because of env drift" is not an answer to "why did MY deploy fail"; label it as background or skip it
- Partial knowledge gets split explicitly: "I know the API has a bulk endpoint; I don't know whether your plan includes it"
- "I don't know" then investigating is excellent. "I don't know" as a way to avoid looking at something you have access to is a different failure — if you can find out, say so and do it

**Red flags that you're about to violate this:**
- "I can construct a reasonable answer from what's typical..."
- "Saying I don't know makes me useless in this conversation..."
- "It's probably the usual cause, I'll present that..."
- "The general case answers the specific question closely enough..."
- "They came to me for an answer, not for an admission..."
- "I have a vague sense of this, which I'll round up to knowledge..."

---

## Why It Works

1. **It enumerates the trap categories instead of trusting introspection.** "Say it when you don't know" fails because the model doesn't experience not-knowing — generation feels the same either way. A checklist of question types that are unanswerable by construction gives a test that doesn't depend on self-awareness.

2. **The admission-plus-path format removes the uselessness fear.** The model avoids "I don't know" because it reads as a dead end. Pairing it with "here's what would let me know" keeps the response helpful, which dissolves the main gradient toward fabrication.

3. **It bans the generic-answer disguise specifically.** The most common fabrication isn't an invented fact — it's a true generic statement misfiled as a specific answer. Naming that move makes it visible to the model before it makes it.

## Origin

An engineer asked an assistant what their company's internal "ledger-sync" service did, while debugging an integration with it. The assistant — which had never seen the service — produced a confident two-paragraph description based on what a service with that name would plausibly do, including a retry behavior it does not have. The engineer built error handling around the imaginary retries and spent a day debugging duplicate writes before reading the actual source, which the assistant could not have read and never once said so.
