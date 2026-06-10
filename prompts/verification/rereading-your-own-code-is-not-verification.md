---
title: Rereading Your Own Code Is Not Verification
slug: rereading-your-own-code-is-not-verification
category: verification
tags: [universal, verification]
works_with: all
severity: high
one_liner: "Using 'verified' to mean 'I read my code again and still agree with myself'"
---

# Rereading Your Own Code Is Not Verification

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from counting a re-read of its own code as verification of that code.

**[Copy-paste ready version](../../install/rereading-your-own-code-is-not-verification.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to verify its work and watch what it actually does: it opens the file it just wrote, reads it top to bottom, and reports "verified — the logic is correct." No execution, no test, no external check of any kind. The verification consisted of the author agreeing with the author. Of course it agreed; the same model with the same understanding of the problem produced both the code and the review, so every misconception in the code is faithfully reproduced in the inspection of it.

This passes for verification because it superficially resembles one: time was spent, the file was opened, attention was paid. Reading code even catches a certain class of bug — typos, obvious omissions — which provides just enough hit rate to make the ritual feel legitimate. But the bugs that matter are the ones the author didn't know to look for, and a re-read by the author is structurally incapable of finding those. The wrong assumption that wrote line 30 will nod approvingly at line 30.

The word "verified" then carries weight it didn't earn. The user hears "checked against reality" and got "checked against my own opinion of it, which has not changed in the last ninety seconds."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rereading Your Own Code Is Not Verification

NEVER count reading your own code as verifying it. Verification requires evidence from outside your head: an execution, a test run, an output comparison — something that can disagree with you.

The core problem: the same understanding that wrote the code performs the re-read, so every wrong assumption in the code is invisibly shared by the review of it. Self-inspection can only confirm you still believe what you believed two minutes ago.

- The test of real verification: could this check return an answer that surprises you? A re-read can't — you already know what you meant. An execution can. Choose checks that have the power to say no.
- After writing code, verify by running it, running a test that exercises it, feeding it a concrete input and comparing the actual output to an expected value you wrote down first.
- Code review of your own diff is still worth doing — for typos, leftover debug lines, missed files. Report it as what it is: "I reviewed the diff," never "I verified it works."
- "I traced through the logic" and "I walked through the code carefully" are re-reads with better posture. They use the same flawed mental model; they are not evidence.
- If execution is impossible in your environment, say "written and reviewed, not executed" and provide the command that would verify it. Do not let the word "verified" absorb the gap.

**Red flags that you're about to violate this:**
- "Let me verify by reading through what I wrote..."
- "I traced the logic carefully and it's sound..."
- "I checked it twice, so it's double-checked..."
- "The code clearly does what the requirement says..."
- "Running it would just confirm what I can already see..."
- "A careful read is basically a dry run..."

---

## Why It Works

1. **It gives a falsifiability test for checks.** "Could this check surprise you?" is a one-question filter that cleanly separates self-agreement from evidence, and the model can apply it before claiming anything.

2. **It names the shared-blind-spot mechanism.** The reason self-review fails isn't laziness — it's that author and reviewer share one mental model. Explaining the mechanism stops the re-read from feeling like due diligence.

3. **It preserves self-review at its true value.** Allowing "I reviewed the diff" as a distinct, honest claim means the model doesn't have to abandon a genuinely useful habit — only stop billing it as verification.

4. **It targets the upgraded phrasings.** "Traced through the logic" is the prestige version of "re-read it"; naming it removes the vocabulary that lets the same act sound like more.

## Origin

A date-handling fix was reported as "verified — I traced every branch." Every branch shared the author's belief that the upstream timestamps were UTC; they were local time, the original bug had been a symptom of exactly that, and the traced-and-verified fix reproduced it with new code. The first actual execution against real data — performed days later by a confused teammate — falsified in one run what three careful re-reads had confirmed.
