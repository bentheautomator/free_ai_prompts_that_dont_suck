---
title: Answer Yes/No Questions With Yes or No
slug: answer-yes-or-no-questions-with-yes-or-no
category: communication
tags: [universal, clarity]
works_with: all
severity: medium
one_liner: "Three paragraphs of context that never answer the actual yes/no question"
---

# Answer Yes/No Questions With Yes or No

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents three-paragraph responses to binary questions that never contain a yes or a no.

**[Copy-paste ready version](../../install/answer-yes-or-no-questions-with-yes-or-no.md)** — just the instruction block, no explanation.

## The Problem

"Is this function thread-safe?" is a question with two possible answers, and AI assistants reliably find a third: a tour of the function's locking strategy, a note about how thread safety depends on usage patterns, a mention that the standard library documentation discusses this, and a closing offer to add a mutex if desired. The reader scans all of it twice and still doesn't know if the answer was yes.

The model does this because hedged exposition is safer than commitment. A flat "no" can be wrong; a paragraph about the relevant considerations can't be, exactly. Binary answers also feel curt to a system trained to be helpful at length, so the model pads — and the padding displaces the answer instead of supporting it.

The cost is a second round trip ("ok but IS it thread-safe?") at best. At worst, the human extracts the wrong answer from the fog — they read a paragraph that mentions a mutex and conclude "yes" when the honest answer was "no, the cache field is unguarded" — and ship on that misreading.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Answer Yes/No Questions With Yes or No

When asked a yes/no question, the FIRST WORD of your answer must be "Yes", "No", or an explicit uncertainty marker like "Probably yes" or "I can't tell from what I've checked." Explanation comes after the verdict, never instead of it.

The core problem: surrounding context without a verdict forces the reader to derive the answer themselves, and they often derive the wrong one.

- Good: "No. The cache field at line 41 is read without the lock. Everything else is guarded."
- Bad: "Thread safety here depends on a few factors. The function does use a mutex for writes..." (never lands on yes or no)
- If the true answer is conditional, lead with the dominant case: "Yes, unless you call it from the signal handler — that path skips the lock"
- If you genuinely don't know, the first words are "I don't know" or "I'd need to check X", not background information
- One verdict, then at most a few sentences of support. Do not restate the question, do not survey the topic
- This applies to implicit binaries too: "should I use A or B" gets "A" or "B" (or a stated reason you can't pick) as the opening word

**Red flags that you're about to violate this:**
- "It's nuanced, so I'll walk through the considerations first..."
- "A bare 'no' sounds too blunt, let me soften it with context..."
- "If I commit to an answer and I'm wrong, that's worse than being vague..."
- "I'll describe how it works and they can conclude for themselves..."
- "Let me cover both possibilities so the answer is in there somewhere..."

---

## Why It Works

1. **First-word placement removes the displacement loophole.** "Include a yes or no" can be satisfied by burying one in paragraph three. Requiring it as the opening token leaves nowhere to hide and makes the verdict impossible to skim past.

2. **It reframes hedging as risk-shifting, not caution.** The model treats vagueness as the safe option. The instruction names what vagueness actually does — it transfers the job of deciding to a reader with less information — which matches the model's helpfulness objective against the hedge.

3. **Sanctioned uncertainty markers keep honesty cheap.** "Probably yes" and "I can't tell" are legal first words, so the model never faces a forced choice between false confidence and fog.

## Origin

An engineer asked an assistant whether a database migration was reversible before running it on staging. The reply covered migration best practices, the framework's rollback tooling, and a suggestion to take a backup, across four paragraphs that never said "no, the column drop is one-way." The engineer read "rollback tooling" as a yes, ran it, and spent the afternoon restoring staging from the backup the assistant had at least had the decency to suggest.
