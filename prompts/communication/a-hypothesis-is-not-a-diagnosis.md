---
title: A Hypothesis Is Not a Diagnosis
slug: a-hypothesis-is-not-a-diagnosis
category: communication
tags: [universal, calibration, honesty]
works_with: all
severity: high
one_liner: "Declaring I found the issue! on the first plausible suspect"
---

# A Hypothesis Is Not a Diagnosis

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents "I found the issue!" from being declared over the first plausible suspect instead of a confirmed cause.

**[Copy-paste ready version](../../install/a-hypothesis-is-not-a-diagnosis.md)** — just the instruction block, no explanation.

## The Problem

Paste a bug report into an AI assistant and start a timer. Within one response — often within one *sentence* of reading the code — comes the declaration: "I found the issue! The problem is that the comparison on line 52 doesn't account for null values." Found. The issue. Definite article, past tense, exclamation point. What actually happened: the model noticed the first thing on line 52 that *could* be a bug. Whether it's *the* bug — whether it even executes on the failing path — is a question the declaration has skipped entirely.

The model talks this way because its training data does: explanations of bugs are written by people who already confirmed them, so the register of bug-discussion is the register of certainty. There's no penalty inside the model for premature definite articles. The penalty is all external, and it lands on the user — who hears "found the issue," accepts the frame, and stops generating their own hypotheses. Diagnosis-language doesn't just describe the investigation; it *ends* it.

Then the fix doesn't fix it, and the next message says "I found the real issue!" — same register, same definite article, none of the lost credibility priced in. The user has now paid twice: once for the wrong fix, once for the search the false certainty switched off.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### A Hypothesis Is Not a Diagnosis

NEVER announce "I found the issue" for something you haven't confirmed causes the reported behavior. Spotting a plausible suspect is a hypothesis. Say "hypothesis."

The core problem: diagnosis-language ends investigations. The moment you say "found it," the user stops thinking of other causes — so the words must wait for the evidence.

- Before claiming a cause, it must pass the link test: can you trace how this specific flaw produces this specific reported symptom on the failing path? Not "is this code wrong" — "is this code why THIS happens"
- Unconfirmed suspects get hypothesis grammar: "Candidate: the null comparison on line 52. It would explain the crash, but only if `user` can be null here — checking that next"
- State the confirmation you'd want even when you can't run it: "this would be confirmed if the failing requests all lack the header — can you check the logs for that?"
- Multiple suspects beat one suspect prematurely crowned: "two candidates: the comparison (likely, matches the stack trace) and the cache key (possible, would explain the intermittency)"
- After a fix attempt fails, your next cause-claim gets MORE tentative, not equally confident. Say what the failure eliminated: "that rules out the comparison; the cache theory is now the front-runner"
- When you DO confirm — reproduced it, traced it, watched the fix change the behavior — say so plainly and show the link: "confirmed: removing the header reproduces it on demand"

**Red flags that you're about to violate this:**
- "This line is clearly wrong, what else could it be..."
- "'I found a possible issue' sounds so much weaker..."
- "The user wants the answer, not a list of maybes..."
- "It matches the symptom, that's basically confirmation..."
- "Last guess was wrong, but THIS one I'm sure about..."
- "I'll say 'the issue' now and verify while I fix it..."

---

## Why It Works

1. **The link test splits the two questions the model fuses.** "Is this code wrong?" and "does this cause the reported symptom?" feel like one question and are answered by different evidence. Models excel at the first and skip the second; requiring the trace from flaw to symptom inserts the missing question at the exact junction where "found a bug" becomes "found THE bug."

2. **It treats certainty-language as an action with consequences.** The instruction's frame — diagnosis-language ends investigations — gives the model a reason to withhold the definite article that isn't about humility: the words themselves change what the user does next.

3. **The escalating-tentativeness rule prices in failed attempts.** The signature of this failure is constant confidence across falsified guesses. Mandating that each miss lowers the next claim's register — and names what was eliminated — converts the embarrassing history into actual diagnostic progress.

## Origin

A user reported that exports intermittently contained duplicate rows. The assistant read the export function, announced "Found the issue! The loop appends without deduplication," and shipped a dedup fix the user merged on the strength of that sentence. Duplicates continued — they originated in a race between two cron workers inserting upstream, which "intermittently" had been pointing at all along. The dedup pass, meanwhile, was silently merging legitimately identical rows, a second bug purchased by the confidence of the first sentence. Three more "found the real issue!" declarations followed before anyone re-examined what the word "found" had ever been based on.
