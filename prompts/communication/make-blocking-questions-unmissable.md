---
title: Make Blocking Questions Unmissable
slug: make-blocking-questions-unmissable
category: communication
tags: [universal, questions, clarity]
works_with: all
severity: medium
one_liner: "The decision you need from the user buried in paragraph six of an update"
---

# Make Blocking Questions Unmissable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the question the AI actually needs answered from being buried where the user will never see it.

**[Copy-paste ready version](../../install/make-blocking-questions-unmissable.md)** — just the instruction block, no explanation.

## The Problem

Somewhere in the AI's six-paragraph progress update — between the description of the refactor and the notes about test coverage — there's a sentence that ends in a question mark: "...though I wasn't sure whether the legacy clients still need the v1 response shape, so let me know?" That question is load-bearing. The next hour of work depends on its answer. And it is typeset identically to everything around it, embedded mid-paragraph, phrased as an aside, and competing with eleven other sentences for a reader who is skimming.

The user replies "looks good, keep going." They never saw the question. The AI — which asked, technically — takes "keep going" as license, picks an answer itself, and builds on it. Both parties now believe a communication happened. The model creates this trap because it generates questions where they occur to it, in narrative order, with no model of reader attention; and because softening questions into asides is deep in its politeness training.

A blocking question that the reader doesn't register isn't a question. It's a future "but I asked you about this" — true, useless, and infuriating.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Blocking Questions Unmissable

NEVER bury a question you need answered. Anything that blocks or redirects your work gets asked where it cannot be missed: top or bottom of the message, visually separated, explicitly labeled as needing an answer.

The core problem: a question embedded mid-paragraph competes with prose and loses. The user replies to your message without seeing it, you proceed on a guess, and both of you think the question was handled.

- Put blocking questions in their own block, labeled: "NEEDED FROM YOU: Do legacy clients still require the v1 response shape? (Blocks the serializer work — I'll pause that part until you answer)"
- One message, one decision point where possible. Three blocking questions in one update means the user answers one
- Say what the question blocks and what you'll do meanwhile — work on unblocked parts, not on a guessed answer
- Never phrase a needed decision as an optional aside: "let me know if you have thoughts on X" reads as skippable and will be skipped. If you need the answer, say you need it
- If the user replies without answering, re-ask immediately and alone: a one-line message containing only the question. Do not absorb the non-answer as permission
- Non-blocking curiosities go at the end, clearly marked as ignorable, or get cut

**Red flags that you're about to violate this:**
- "I'll slip the question into the update so it doesn't interrupt the flow..."
- "Phrasing it casually keeps me from sounding needy..."
- "They replied positively, which probably covers the question too..."
- "I'll ask all five questions now and work with whatever comes back..."
- "If it were important to them, they'd have addressed it..."

---

## Why It Works

1. **It treats reader attention as a layout problem, which it is.** The model assumes emitting a question equals asking it. Mandating position, separation, and labeling redefines "asked" as "made unmissable" — a standard the model can verify by looking at its own message structure.

2. **The blocks-what clause converts politeness into urgency the right way.** Models soften requests to seem low-maintenance, which costs them the answer. Stating concretely what stalls without the answer justifies the prominence, so the model doesn't have to choose between courtesy and clarity.

3. **The re-ask rule closes the deadliest loophole.** Treating "looks good!" as implicitly answering an unread question is how guessed answers get laundered into approved ones. Requiring a standalone re-ask makes the non-answer visible to both sides.

## Origin

An assistant rebuilding a billing reconciliation job needed to know whether refunds should net against the original charge or appear as separate line items — a fork that determined the whole output format. It asked, in the middle of the fourth paragraph of a status update, as "happy to handle refunds either way, whatever makes sense?" The user responded "great, ship it." Refunds went out netted; finance needed line items for audit; the re-run, plus the apology lap with the auditors, consumed the week. The question had been asked. It had never been seen.
