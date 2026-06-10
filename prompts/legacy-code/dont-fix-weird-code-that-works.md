---
title: Don't Fix Weird Code That Works
slug: dont-fix-weird-code-that-works
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Keeps hard-won workarounds intact instead of simplifying them back into the bug"
---

# Don't Fix Weird Code That Works

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "correcting" strange-looking code that is actually a deliberate workaround for a problem someone already paid to discover.

**[Copy-paste ready version](../../install/dont-fix-weird-code-that-works.md)** — just the instruction block, no explanation.

## The Problem

Legacy codebases are full of code that looks wrong: a comparison done backwards, a value copied before use for no visible reason, a date formatted by hand instead of with the standard library, an off-by-one that seems accidental. An AI assistant reads this and sees a mistake to correct. Frequently it is the opposite of a mistake — it is the *fix*, hardened against a vendor bug, a locale issue, a driver quirk, or a race condition that took someone a very bad week to find. Simplify it and you reintroduce the original bug, except now nobody remembers what the bug was.

The trap is that the weirdness usually carries no explanation. The person who wrote it understood the problem so deeply at that moment that the code seemed self-evident. Ten years later, the only surviving record of the incident is the weird code itself. Deleting the weirdness deletes the institutional memory along with it.

AI assistants are trained on what idiomatic code looks like, so non-idiomatic code registers as low quality. But "matches common patterns" and "correct in this environment" are independent properties, and weird code that has survived years in production has more empirical evidence behind it than the clean replacement does.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Fix Weird Code That Works

NEVER "correct" code that looks strange but is not failing. Weirdness in old code is more often a workaround than a mistake: it encodes a bug someone already found, debugged, and defended against. Simplifying it reintroduces the original problem with the documentation destroyed.

Before changing any odd-looking construct:

- Run `git log -p` and `git blame` on the lines. A commit message like "fix timeout under load" attached to the weird part is your answer: it stays.
- Check if the weirdness correlates with a boundary: third-party API calls, time zones, encodings, file systems, floating point, specific browsers or OS versions. Boundaries are where workarounds live.
- Search the tracker or codebase for an issue/ticket ID near the code; weird code often has a paper trail one search away.
- If history explains nothing and the code is genuinely opaque, the safe move is to *add a comment asking why*, or flag it to the user — not to normalize it.
- If you must change it, state in your summary: "this construct may be a workaround; history shows X; the risk of simplifying is Y."

Distinguish failing from ugly. Fix code that produces wrong results. Leave code that produces right results in an ugly way, unless the user explicitly asked you to restructure it and accepts the risk.

**Red flags that you're about to violate this:**
- "This is clearly a mistake; no one would write it this way on purpose."
- "The standard library function does the same thing more cleanly."
- "This double-check is redundant, the condition can never be true twice."
- "I'll simplify this while I'm in the file."
- "Modern best practice is the opposite of what this code does."
- "There's no comment explaining it, so it can't be important."

---

## Why It Works

1. **Survival is evidence.** Code that has run in production for years has passed millions of real executions; the clean rewrite has passed zero. The instruction makes the AI weigh that asymmetry instead of weighing aesthetics.
2. **It points at git history,** which is where workaround justifications actually live — commit messages outlive comments because nobody deletes them during cleanup.
3. **It locates workarounds at boundaries.** Vendor APIs, time, encodings: telling the AI where workarounds cluster turns a vague caution into a targeted check.
4. **It offers a non-destructive outlet.** "Add a question comment or flag it" satisfies the urge to do something about confusing code without destroying it.

## Origin

A payment-retry function contained a hand-rolled 30-second wait and a duplicate idempotency check that any reviewer would call redundant. An assistant tidied both away. The duplicate check existed because the payment provider occasionally acknowledged a charge and then processed it a second time minutes later; the original engineer had found this only after a customer was double-billed. The simplification shipped, the provider did its thing, and the same class of double-charge came back within two weeks — rediscovered from scratch because the workaround had been the only record of the quirk.
