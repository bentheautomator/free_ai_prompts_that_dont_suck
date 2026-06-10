---
title: Write Down Agreements Made in Chat
slug: write-down-agreements-made-in-chat
category: collaboration
tags: [universal, teamwork, process]
works_with: all
severity: medium
one_liner: "Stops decisions and assumptions living only in a chat session nobody can see"
---

# Write Down Agreements Made in Chat

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents decisions, assumptions, and constraints agreed in the AI conversation from existing nowhere the rest of the team can see them.

**[Copy-paste ready version](../../install/write-down-agreements-made-in-chat.md)** — just the instruction block, no explanation.

## The Problem

Real decisions get made inside AI sessions. "Let's assume orders are always under 10k items." "We'll skip retries here because the upstream dedupes." "Use the legacy endpoint for now; the new one isn't ready." The user and the AI agree, the code gets written accordingly, and the agreement evaporates when the session ends. What survives is code shaped by a decision that is recorded nowhere: no comment, no doc, no commit message, no ticket. A side agreement, in the contract-law sense — binding on the code, invisible to the parties who'll maintain it.

The team inherits the shape without the reason. A reviewer asks why there are no retries and gets no answer from the diff. A teammate "fixes" the missing retry handling, breaking the dedup assumption it encoded. Six months later someone needs to know whether the 10k-item assumption is load-bearing, and the only record was a conversation that no longer exists, with an AI that no longer remembers it. Chat-scoped decisions rot faster than any other kind of tribal knowledge, because at least tribal knowledge lives in a human who can be asked.

This is a default failure, not a malicious one: the AI treats the conversation as the workspace, and anything established there feels established. It has no instinct that the session is a private room and the codebase is the public record.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Write Down Agreements Made in Chat

ALWAYS move decisions out of the conversation and into artifacts the team can see. Anything agreed in this session — assumptions, constraints, trade-offs, deferrals — is invisible to everyone else and will be forgotten by both of us. If it shaped the code, it must be recorded where the code lives.

- When the user and you settle a consequential point ("assume X," "skip Y because Z," "temporary until the new API ships"), put it in a durable home: a code comment at the load-bearing spot, the PR description, a doc, or the commit message. Pick the place a future maintainer would actually encounter it.
- Record assumptions where they'd break: a comment like `// Assumes upstream dedupes; do not add retries without checking` at the exact line someone would otherwise "fix."
- Make temporary explicit: anything agreed as a stopgap gets a marker stating what it's waiting on, not just a bare TODO.
- When the user gives you a constraint from outside the session ("ops said the queue caps at 1k"), that's secondhand tribal knowledge — write it down with its source, because you're currently its only record.
- At the end of substantial work, list the session-local decisions baked into the code so the user can see what would otherwise be lost, and where you recorded each.
- Don't bloat code with conversational trivia. The bar: would a maintainer act differently knowing this? If yes, record it; if no, skip it.

**Red flags that you're about to violate this:**
- "We discussed this earlier in the session, so it's settled."
- "The code makes the assumption obvious." (It makes the behavior obvious, not the reason.)
- "I'll keep the summary in chat; the user can copy it somewhere."
- "It's temporary, not worth documenting."
- "Explaining the why in a comment feels redundant."

---

## Why It Works

1. **It treats the session as volatile memory** — which it literally is — and forces a flush to durable storage before the contents are lost to both parties.
2. **It co-locates assumptions with their blast site**, so the warning is read at the exact moment someone is about to violate it, not in a doc nobody opens.
3. **It captures secondhand constraints with provenance**, converting "someone said once" into a checkable record before the chain of custody breaks.
4. **It uses the would-a-maintainer-act-differently bar**, keeping the rule from degenerating into comment spam that buries the real decisions.

## Origin

A developer and their assistant agreed in-session to skip idempotency keys on a payment retry path because "the gateway dedupes within 24 hours" — a fact the developer had from a vendor call. Nothing was written down. A year later, a different engineer, seeing retries without idempotency keys, flagged it as a bug and added keys with a new format the gateway treated as distinct requests. The vendor's dedup no longer applied, and a flaky network day produced a small batch of double charges. The original reasoning was correct, secret, and therefore useless.
