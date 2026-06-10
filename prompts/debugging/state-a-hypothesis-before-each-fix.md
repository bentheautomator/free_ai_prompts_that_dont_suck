---
title: State a Hypothesis Before Each Fix
slug: state-a-hypothesis-before-each-fix
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI making 'let's try this' edits with no falsifiable theory behind them"
---

# State a Hypothesis Before Each Fix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents guess-and-check debugging — edits made to "see if this helps" with no stated theory of what's wrong.

**[Copy-paste ready version](../../install/state-a-hypothesis-before-each-fix.md)** — just the instruction block, no explanation.

## The Problem

"Let me try converting this to async and see if that resolves it." Try? See? That's not a diagnosis, it's a slot machine pull. A meaningful share of AI debugging consists of edits with no articulated theory behind them — changes selected because they're *adjacent* to the symptom and *plausible* as a category, made to observe whether the error goes away. When one finally does make the error go away, that's what ships, with no one able to say what the bug actually was.

The deep problem with theory-free edits is that their results are uninterpretable. If "try making it async" fails, what have you learned? Nothing — there was no claim to falsify. Twenty such attempts produce twenty shrugs, where five hypothesis-driven experiments ("I believe the handler runs before the listener registers; if so, logging registration order will show it") would have produced five eliminations and likely the answer. Guessing also selects fixes by *plausibility of the edit* rather than *truth of the cause*, which is exactly how a wrong-but-plausible change ends up masking a bug instead of fixing it.

Models drift into this mode under pressure because generating a plausible edit is always available, while forming a falsifiable theory requires the investigation they're trying to skip.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### State a Hypothesis Before Each Fix

NEVER make a debugging edit without first stating, in one sentence, what you believe is wrong and what observation would prove or disprove it. "Let's try X and see" is not debugging; it's gambling with the codebase as chips.

An edit without a hypothesis produces an uninterpretable result: if it fails you've learned nothing, and if it "works" you don't know why — which means you don't know whether it actually fixed anything.

- Before each change, write the hypothesis in this shape: "I believe <specific cause> is producing <observed symptom> because <mechanism>. If true, <observable prediction>."
- Prefer testing the hypothesis with observation (a log, a debugger check, an isolated call) before testing it with a fix — confirmation is cheaper than modification
- A failed attempt must update your model: state what the failure eliminated before proposing the next hypothesis
- If you cannot form any hypothesis, that is a signal to gather more information (reproduce, instrument, read the trace), not a license to start trying things
- Rank competing hypotheses by evidence, not by which one has the easiest edit
- Words like "try," "maybe," "might help," and "see if" in your fix description mean the hypothesis step was skipped — go back and do it

**Red flags that you're about to violate this:**
- "Let me try changing this and see if it helps..."
- "It might be a caching thing; I'll disable the cache and check..."
- "Worth a shot to bump this dependency..."
- "I have a few ideas, I'll just go through them..." (ideas, not predictions)
- Choosing the next fix because it's easy to make, not because evidence points there
- Unable to say what you'd expect to observe if your current theory were true

---

## Why It Works

1. **It makes results carry information.** A stated prediction turns every run into a confirmation or an elimination; without one, even a "successful" run is just a coincidence with good PR.

2. **It inserts observation before modification.** Most hypotheses can be checked with a log line for a fraction of the cost of a fix-and-rerun; the instruction restores that cheaper step the guessing loop skips entirely.

3. **It uses the AI's own vocabulary as a tripwire.** "Try," "see if," "might" are the literal tokens of theory-free debugging; flagging them gives the model a self-detection mechanism that fires at exactly the right moment.

4. **It decouples fix-selection from fix-convenience.** Forcing evidence-ranked hypotheses breaks the gradient where the easiest edit gets tried first regardless of likelihood.

## Origin

A webhook handler dropped roughly one event in fifty, and an assistant cycled through six "let's try" edits across a session: added a retry, raised a body-size limit, switched JSON parsers, disabled compression, reordered middleware, pinned a dependency. The fifth one appeared to work, shipped, and the drops returned in two days. A hypothesis-driven pass afterward took four steps: predicted the drops correlated with concurrent deliveries, confirmed it in logs, found a non-atomic read-modify-write on the dedupe key, fixed that. The six guesses had never been within a mile of it.
