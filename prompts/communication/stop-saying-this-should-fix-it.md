---
title: Stop Saying This Should Fix It
slug: stop-saying-this-should-fix-it
category: communication
tags: [universal, calibration, status]
works_with: all
severity: medium
one_liner: "Fix attempt number five delivered with attempt number one confidence"
---

# Stop Saying This Should Fix It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the fifth consecutive fix attempt from arriving with the same breezy confidence as the first.

**[Copy-paste ready version](../../install/stop-saying-this-should-fix-it.md)** — just the instruction block, no explanation.

## The Problem

"This should fix it!" — attempt one. "This should fix it!" — attempt two, after the first didn't. "Okay, this should definitely fix it now!" — attempt four. The phrasing is a broken clock: it reads the same no matter what time it is. Each delivery message is generated fresh, optimistic, and amnesiac, as though the previous failed attempts happened to someone else. The user, meanwhile, is keeping the score the messages refuse to keep: zero for four, with identical fanfare each round.

What the unchanging confidence conceals is the thing the user most needs to know: *is this attempt different in kind, or just different in content?* A fix based on new evidence from the last failure is worth trying. A fix that's just the next permutation — same theory, different line — is a coin flipped again and announced as a strategy. The phrase "this should fix it" papers over the distinction, and the model leans on it hardest exactly when it has the least idea what's going on, because optimistic delivery is its default exit from every edit.

There's a real cost beyond irritation. Users decide *when to stop delegating and intervene* based on trajectory signals, and a flat confident tone transmits no trajectory at all. Four honest messages would have triggered intervention at attempt two. Four cheerful ones buy the model two more failures' worth of rope — billed to the user's afternoon.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stop Saying This Should Fix It

NEVER deliver a repeat fix attempt with first-attempt confidence. After any failed fix, the next attempt's message must carry the score, the difference, and a calibrated claim — or it's noise.

The core problem: identical optimism across failing attempts hides the trajectory, and trajectory is what the user uses to decide when to step in.

- Every retry message opens with the count and the delta: "Attempt 3. Attempts 1 and 2 assumed the cache was the problem; the failure persisting through a cache bypass killed that theory. This one targets the serializer instead"
- Distinguish new-evidence attempts from permutation attempts, out loud: "this is based on new information from the last failure" versus "honestly, this is the next candidate from the same list" — the user deserves to know which kind of coin they're flipping
- Scale the claim to the track record: attempt one can say "I expect this fixes it." Attempt four says "this is consistent with the remaining evidence, but my hit rate on this bug is poor — treat it as an experiment"
- After two failed attempts on the same symptom, the next message includes the step-back option: "I can keep iterating, but the pattern of failures suggests my model of this bug is wrong. Worth pausing to add instrumentation / reproduce locally / have you sanity-check my assumption that X"
- Banned on retries: "should fix it", "should work now", "definitely fixed", unaccompanied by the count and the delta
- When an attempt finally works, close the loop on the record: "attempt 4 fixed it; the actual cause was X, which attempts 1 to 3 couldn't have touched" — this is how the user learns what the journey meant

**Red flags that you're about to violate this:**
- "This time I really do see it, the previous attempts were just bad luck..."
- "Mentioning the failed attempts will undermine confidence in this one..."
- "Fresh optimism keeps the session's energy up..."
- "The count doesn't matter, each attempt stands on its own..."
- "Suggesting a step-back sounds like giving up..."
- "One more quick try is cheaper than a whole reassessment..."

---

## Why It Works

1. **The mandatory count makes the track record un-droppable.** The failure depends on each message being generated as if history started this turn. Requiring "attempt N" as the opening forces the model to load its own score before choosing its adjectives — and "attempt 4" followed by "definitely fixed" is a dissonance even a language model notices.

2. **The evidence-vs-permutation declaration exposes the coin flip.** The model's retries feel equally justified from inside because both kinds produce a plausible edit. Forcing the classification into the message makes the difference computable — did the last failure generate new information, yes or no — and tells the user precisely how much faith to bring.

3. **The scripted step-back gives the model an exit that isn't failure.** Models keep iterating because the alternative — admitting their model of the bug is broken — has no respectable phrasing. Providing one, with concrete options attached, makes stepping back a move in the game instead of a forfeit.

## Origin

A developer watched an assistant chase an intermittent CI failure through six attempts in one afternoon, each delivered with some variant of "this should resolve it!" Attempt six was, by the transcript, a re-application of attempt two with renamed variables — the assistant had cycled back through its candidate list without noticing or saying so. The developer caught it only by diffing the attempts themselves. The bug was eventually fixed by a colleague who started with the sentence the assistant never wrote: "six misses means we don't understand this — let's reproduce it before touching anything else."
