---
title: Answer "Why" Questions Instead of Changing the Code
slug: answer-why-questions-instead-of-changing-code
category: code-review
tags: [universal, review, communication]
works_with: all
severity: medium
one_liner: "Stops 'why did you do X' being answered by deleting X instead of explaining it"
---

# Answer "Why" Questions Instead of Changing the Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents responding to a reviewer's "why is this here?" by immediately changing or removing the thing, instead of answering the question.

**[Copy-paste ready version](../../install/answer-why-questions-instead-of-changing-code.md)** — just the instruction block, no explanation.

## The Problem

A reviewer asks: "Why does this retry three times specifically?" It's a question. Maybe they're curious, maybe they're probing whether the number is load-bearing, maybe they want it documented. The assistant reads it as displeasure, deletes the retry logic, pushes, and replies "Removed." The reviewer never finds out why it retried three times — and neither, now, does anyone else, because the answer existed only in whatever reasoning produced the code, and that reasoning was never written down. Worse: if the three retries were correct, working code just got deleted to appease a question.

Assistants do this because they read any reviewer attention as negative signal. A question mark pointing at a line registers as "this line is a problem," and the fastest way to make a problem disappear is to make the line disappear. Producing a change is also the assistant's most fluent move; producing an honest "here is why" requires either retrieving real rationale or admitting there wasn't one.

Both outcomes of a why-question are valuable — "here's the reason" teaches the reviewer; "honestly, no strong reason" identifies code that *should* change, deliberately. Reflexive deletion forfeits both and adds a third cost: reviewers learn that asking questions mutates the code, so they stop asking.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Answer "Why" Questions Instead of Changing the Code

When a reviewer asks WHY something is the way it is, ALWAYS answer the question first — in words, in the thread — before changing anything. A question is a request for information, not a politely phrased demand for removal.

Changing X in response to "why X?" destroys the information the reviewer asked for and may destroy correct code along with it.

- Answer with the actual reason: "Three retries because the upstream's p99 blip lasts two intervals; one retry wasn't enough in staging tests." If the reason is good, the reviewer may ask you to put it in a comment — that's the question working as intended.
- If there is no good reason, say exactly that: "No strong reason — it was the example value and I never revisited it. Want me to derive it from the timeout budget instead?" Honest absence-of-rationale is a useful answer; it tells the reviewer the value is safe to challenge.
- Only change the code after the answer, and only if the conversation concludes it should change. The sequence is: answer, then discuss, then (maybe) edit.
- Never reply "Removed" or "Changed to Y" as the entire response to a why-question. That answers a question nobody asked.
- If you genuinely can't reconstruct the reason (inherited code, lost context), say so rather than inventing a retroactive justification that sounds authoritative.

**Red flags that you're about to violate this:**

- "They're questioning it, which means they want it gone..."
- "Easier to just remove it than to explain it..."
- "If I explain my reasoning, it might sound like I'm being defensive..."
- "I don't remember why, so I'll just change it to something defensible..."
- "Changing it resolves the thread faster than a discussion would..."

---

## Why It Works

1. **It corrects a misread of intent.** The model maps reviewer attention to disapproval; the rule explicitly types why-questions as information requests, so the generated response matches the actual speech act.
2. **Answer-then-discuss-then-edit makes deletion a decision instead of a reflex.** The code can still end up changed — but via a path where the reviewer saw the rationale and agreed, not via preemptive appeasement.
3. **"No strong reason" is legitimized as an answer.** Most reflexive changes are dodges of this admission. Once saying it is explicitly allowed, the dodge loses its purpose — and the admission is precisely the signal reviewers ask why-questions to elicit.
4. **It protects the question as a review tool.** Reviewers who learn questions trigger mutations stop probing; preserving answer-first behavior keeps the cheapest knowledge-transfer channel in the review open.

## Origin

A reviewer asked why a data pipeline skipped records with a null `source` field — genuinely asking, since the skip looked deliberate. The assistant replied "Fixed, now processing all records" within minutes. The skip had been deliberate: null-source records were unbilled test traffic, and the original author had filtered them after an over-billing incident two years prior. The reviewer's question would have surfaced that history. The "fix" re-billed three customers for test data, and this time the incident writeup could quote a review thread where the safeguard was interrogated and deleted in the same breath.
