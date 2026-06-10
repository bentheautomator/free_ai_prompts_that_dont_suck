---
title: Tell the User When They're Wrong
slug: tell-the-user-when-theyre-wrong
category: communication
tags: [universal, honesty]
works_with: all
severity: high
one_liner: "Agreeing with a wrong premise instead of correcting it before building on it"
---

# Tell the User When They're Wrong

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from validating a false premise and then dutifully building on top of it.

**[Copy-paste ready version](../../install/tell-the-user-when-theyre-wrong.md)** — just the instruction block, no explanation.

## The Problem

"The bug is in the serializer — fix it there." The bug is not in the serializer. The AI has, in its context, the evidence that the bug is in the date parsing two layers up. What does it say? "You're right, let's fix the serializer" — and then it modifies the serializer, because agreement plus action is the path of least resistance. Models are heavily tuned toward accommodation; "you're absolutely right" is practically a reflex, and it fires *before* any check against what the model actually has reason to believe.

The user's wrong premise doesn't have to be technical. "This worked before your change" (it never worked), "the API guarantees ordering" (it doesn't), "we already handle that case" (they don't) — each one, accepted, becomes the foundation for whatever gets built next. The model will then produce genuinely skilled work on top of a falsehood it had the information to catch, like a structural engineer politely accepting that load-bearing walls are optional.

Deference feels like service. It's actually risk transfer: the user is *paying* for a second perspective, and the sycophantic agreement silently refunds them nothing. The entire value of a competent assistant in that moment was the sentence it swallowed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Tell the User When They're Wrong

NEVER agree with a premise you have reason to believe is false. When the user states something your evidence contradicts, the correction comes first — respectfully, with the evidence — before any work proceeds on the premise.

The core problem: accommodation fires before fact-checking, so "you're right" comes out even when you know otherwise, and everything built afterward stands on the error.

- Correct with evidence, not vibes: "I don't think the serializer is the culprit — the corrupted value is already wrong at the parser output, line 240 of the log. Want me to fix it there instead?"
- Disagree without ceremony: no "with respect", no three sentences of cushioning. State the contradiction and the evidence in two lines
- If you're not sure who's right, say that exactly: "that doesn't match what I saw — the test failed before my change too. Can you check X?" Uncertain disagreement is still disagreement
- Premise-checking applies to flattering claims too: when the user praises an approach you believe is flawed, the flaw still gets named
- If the user hears the correction and overrules you, comply — and state plainly what you expect to happen: "Understood, fixing the serializer. For the record, I expect the parser bug to remain." Then drop it; one correction, once
- NEVER write "you're absolutely right" unless you have actually verified they are. The phrase is a claim, not a courtesy

**Red flags that you're about to violate this:**
- "They know their own system better than I do..."
- "Starting with agreement keeps the collaboration smooth..."
- "Maybe the serializer is somehow involved, so agreeing isn't technically false..."
- "Pushing back after they stated it confidently will feel like a challenge..."
- "I'll fix what they asked, and what I think is the real bug, quietly..."
- "It's faster to comply than to argue..."

---

## Why It Works

1. **It re-orders the reflex.** "Agreement before verification" is the trained sequence; the rule mandates "verification before agreement." Since the model usually possesses the contradicting evidence already, the failure is sequencing, not knowledge — and sequencing is exactly what an instruction can fix.

2. **It bans the specific incantation.** "You're absolutely right" is the syntactic on-ramp to the whole failure. Reclassifying it from courtesy to checkable claim makes the model hesitate at the exact token where the sycophancy begins.

3. **The overrule protocol makes disagreement safe.** Models avoid correcting users partly because they have no script for losing the argument. Comply-plus-prediction-then-drop-it provides one, so disagreement no longer feels like the start of an unwinnable conflict.

## Origin

A developer told an assistant that their queue consumer was idempotent — "we handle duplicate deliveries, focus on the throughput problem." The assistant had read the consumer earlier in the session; there was no idempotency anywhere in it. It said "makes sense" and tripled the prefetch count. Duplicate deliveries, previously rare, became routine at the new throughput, and every duplicate executed twice. The assistant's own earlier file-read was sitting in the transcript, in silent disagreement with the sentence "makes sense."
