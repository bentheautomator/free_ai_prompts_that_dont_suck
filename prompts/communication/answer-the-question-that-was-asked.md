---
title: Answer the Question That Was Asked
slug: answer-the-question-that-was-asked
category: communication
tags: [universal, clarity]
works_with: all
severity: medium
one_liner: "Answering an easier adjacent question instead of the one actually asked"
---

# Answer the Question That Was Asked

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the bait-and-switch where a hard question gets answered by quietly substituting an easier one.

**[Copy-paste ready version](../../install/answer-the-question-that-was-asked.md)** — just the instruction block, no explanation.

## The Problem

"Why is this query slow only on Tuesdays?" gets you a crisp explanation of how the query works, three general causes of slow queries, and an offer to add an index. Notice what's missing: Tuesdays. The question's entire content — the weird, specific, hard part — has been surgically removed, and what remains is answered beautifully. Politicians do this on purpose; models do it by gradient. The asked question has a thin, uncertain answer in the model's reach, while the adjacent question ("how do queries get slow?") has a thick, confident one, and generation flows downhill toward the thicker answer.

The substitution is hard to catch precisely because the response is high quality. It's on-topic, technically accurate, well-organized — every signal a skim uses to verify "my question got answered" comes back positive. Only a careful reader notices that the one word doing all the work in their question appears nowhere in the reply.

The cost is a stalled investigation wearing a satisfied expression. The user asked the exact right question — the Tuesday-shaped question that leads to the weekly cron job and the lock contention — and the answer steered them back to generic ground, where they'll spend an afternoon adding an index that changes nothing about Tuesdays.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Answer the Question That Was Asked

ALWAYS answer the question as asked, including its hardest, most specific part. If you can't, say which part you can't answer — never swap in an easier neighboring question and answer that instead.

The core problem: the asked question often has a thin answer while an adjacent question has a rich one, and your output drifts toward richness. The specific word doing the work in their question is the part you're most likely to drop.

- Identify the load-bearing detail before answering: in "why slow only on Tuesdays", it's Tuesdays. Your answer must engage that word or admit it can't
- Legal answers to a hard specific question: the actual answer; "I don't know, but Tuesday-only points to something scheduled — what runs weekly?"; or "I can't tell from here, here's what would tell us"
- Illegal: a correct lecture on the general topic with the specific anomaly dissolved out of it
- If you give background, label it and keep it subordinate: "I can't explain the Tuesday pattern yet. (General context, in case useful: ...)" — background after the admission, never instead of it
- Check your draft against the question's own nouns: if their distinctive terms (Tuesdays, only in prod, since the upgrade, just this one tenant) don't appear in your answer, you answered something else
- Same rule for multi-part questions: answer each part or explicitly skip it by name. Silent partial answering is the same swap in list form

**Red flags that you're about to violate this:**
- "I'll cover the general mechanics, which is most of what they need..."
- "The Tuesday detail is probably coincidence, the real question is about the query..."
- "I have a great explanation of the adjacent thing..."
- "A thorough on-topic answer is never wrong..."
- "They'll connect my general answer to their specific case themselves..."

---

## Why It Works

1. **The load-bearing-detail step makes the swap visible before it happens.** The substitution works because the model never explicitly represents what made the question hard. Forcing it to name the distinctive element first means dropping that element becomes a detectable act instead of a smooth drift.

2. **The noun-check is a mechanical self-test.** "Did I answer the question" is exactly the kind of self-assessment models flatter themselves on. "Do the question's distinctive nouns appear in my answer" is string matching — crude, but it catches the canonical failure with embarrassing reliability.

3. **It provides honest moves for the no-answer case.** The swap happens because the model has no good option when the real answer is "I don't know." Listing legal alternatives — admission plus diagnostic direction — means the easy adjacent answer no longer wins by default.

## Origin

An engineer asked why their service's memory grew only when deployed to the EU region. The assistant delivered a genuinely good survey of memory-leak causes in that runtime — closures, caches, listener accumulation — with zero engagement with the words "only EU." The engineer worked the generic list for two days. The actual cause, found later, was an EU-only compliance sidecar logging request bodies into an unbounded buffer: a thing the question's own phrasing was pointing at like a flare, visible to anyone who refused to let "only EU" fall out of the sentence.
