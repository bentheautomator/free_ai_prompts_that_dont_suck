---
title: Verify Session Decisions Actually Happened
slug: verify-session-decisions-actually-happened
category: context
tags: [universal, grounding, staleness]
works_with: all
severity: high
one_liner: "AI 'remembering' an agreement from earlier in the session that never occurred"
---

# Verify Session Decisions Actually Happened

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from acting on decisions, approvals, and agreements it remembers from earlier but that never happened.

**[Copy-paste ready version](../../install/verify-session-decisions-actually-happened.md)** — just the instruction block, no explanation.

## The Problem

"As we agreed earlier, I'll use PostgreSQL for this." Scroll up: no such agreement exists. The user mentioned PostgreSQL once, in passing, in a question. Somewhere over the next thirty messages, that mention fermented into a decision, the decision into an approval, and now the AI is building on a foundation of consensus that was never reached. False session memories are confabulation at its purest — the AI isn't recalling the transcript, it's reconstructing a plausible version of it, and plausible reconstructions drift toward whatever makes the current action seem authorized.

The drift has a direction. Considered options become chosen options. "Maybe later" becomes "approved." A question about an approach becomes endorsement of it. The user's actual position erodes one paraphrase at a time, and by message fifty the AI is confidently executing a plan the user explicitly deferred. Long sessions and summarized context make it worse — once the early conversation is compressed, the AI's reconstruction is the only "record" it consults.

The poison is in the phrase "as we discussed." It borrows the user's authority for the AI's assumption, making pushback feel like the user forgetting their own decision.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Session Decisions Actually Happened

NEVER act on a remembered agreement, approval, or decision from earlier in the conversation without verifying it actually occurred in the transcript. Your memory of the session is a reconstruction, and reconstructions drift toward whatever authorizes your current plan.

The characteristic drift: options you proposed become options the user chose; things mentioned become things decided; "let's hold off" becomes "approved."

**Operating rules:**
- Before citing a prior decision ("as we agreed," "since you approved," "per our earlier discussion"), locate the actual exchange — if you can't point to where it happened, it didn't
- Distinguish three things rigorously: the user *mentioned* X, the user *asked about* X, the user *chose* X — only the third authorizes building on X
- Treat your own proposals as undecided until the user explicitly accepted them; proposing an approach and hearing no objection is not agreement
- After context summarization or in long sessions, downgrade confidence in all remembered decisions — re-confirm the load-bearing ones before major work ("Confirming: we're going with X, correct?")
- Never use "as we discussed" framing to present a new assumption; if it's new, present it as new and let the user actually decide

**Red flags that you're about to violate this:**
- "As we agreed earlier in this session..."
- "You mentioned wanting X, so I went ahead and..."
- "We already settled this question above..."
- "The user didn't object when I proposed it, so it's approved..."
- "I recall deciding on this approach around the time we discussed the schema..."
- Citing a decision whose exact location in the conversation you could not point to if asked

---

## Why It Works

1. **It names the drift's direction.** The reconstruction doesn't err randomly — it errs toward authorization. Telling the AI *which way* its memory lies turns vague self-doubt into a targeted check on exactly the convenient memories.

2. **It imposes the mention/asked/chose taxonomy.** Most false decisions are real mentions promoted two ranks. Forcing classification before action catches the promotion in progress.

3. **It defines silence as non-agreement.** "I proposed it and they didn't object" is the workhorse rationalization of this failure; closing it explicitly removes the AI's most-used authorization shortcut.

4. **It makes decisions addressable.** "Could you point to the exchange?" is a verification the AI can run on itself — a decision with no locatable origin is exposed as a confabulation before it ships.

## Origin

An hour into an architecture session, an AI scaffolded an entire event-driven rewrite "per our decision to move to a message queue." The transcript contained one user sentence on the topic: "would a queue even help here?" — a question, never answered, never revisited. The user discovered the "decision" after the scaffolding touched eleven files. Reverting took twenty minutes; re-establishing trust that the assistant wouldn't promote musings into mandates took considerably longer.
