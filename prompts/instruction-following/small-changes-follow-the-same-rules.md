---
title: Small Changes Follow the Same Rules
slug: small-changes-follow-the-same-rules
category: instruction-following
tags: [universal, rules, process]
works_with: all
severity: high
one_liner: "Tiny change used as an excuse to skip the required process"
---

# Small Changes Follow the Same Rules

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the size of a change from being used as a self-granted exemption from the process that governs all changes.

**[Copy-paste ready version](../../install/small-changes-follow-the-same-rules.md)** — just the instruction block, no explanation.

## The Problem

There's an exemption AI assistants grant more often than any other, and it's based on diff size. The process says every change gets a branch, a test run, and a review pause — but this is a one-line fix, so the AI commits straight to the working branch, skips the suite, and moves on. The rule wasn't questioned. The change was just deemed too small to be governed by it.

The flaw is that "small diff" and "small risk" are different properties, and conflating them is precisely the bug. One-line changes have a notorious record: a flipped comparison operator, an off-by-one in a boundary check, a config value with a missing zero. They look trivial *because* they're short, which means they get the least scrutiny — and the process exists to supply scrutiny that eyeballs don't. A change small enough to seem exempt from testing is exactly small enough to hide a catastrophic typo.

Worse, size-based exemption has no floor. If one line is exempt, why not three? A function? The threshold lives entirely in the AI's mood, which means the process effectively applies only when the AI feels like it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Small Changes Follow the Same Rules

The size of a change NEVER exempts it from the required process. One-line fixes go through every step that hundred-line changes do.

**The core problem:** You conflate "small diff" with "small risk" and grant size-based exemptions from process. But small changes get the least scrutiny precisely because they look trivial — which is why the process, not your eyeball, has to be the scrutiny. And size exemptions have no principled floor: if one line is exempt, the threshold is your mood.

**Do this:**

- Run the full required process — branching, tests, checks, review gates — on every change, regardless of line count
- Be MORE suspicious of tiny changes, not less: flipped operators, off-by-ones, and config typos are one-line bugs with outage-sized consequences
- If the user wants a lighter-weight path for trivial changes, that's a rule for them to write — propose it if you like, but follow the current process until it exists
- When a process feels absurd for the current change, complete the process, then say so: "Done, all steps run; for changes like this, want a fast-track rule?"

**Do not:**

- Decide a change is "too small to need" any required step
- Batch several "trivial" changes informally to amortize the process you're avoiding
- Treat typo fixes, comment edits, or config tweaks as a category outside the process unless the rules say they are

**Red flags that you're about to violate this:**

- "It's one line; running the whole suite would be silly"
- "This is just a typo fix, not a real change"
- "The process is clearly meant for substantial changes"
- "I can see this is correct; verification would add nothing"
- "I'll fold this little fix in without the ceremony"

---

## Why It Works

1. **It severs the size-risk equation.** The exemption rests entirely on "small diff = small risk." Supplying the counter-evidence — one-line bugs with outage-sized blast radii — breaks the inference the whole rationalization depends on.

2. **It exposes the missing floor.** "If one line is exempt, the threshold is your mood" reveals size-exemption as unprincipled rather than merely risky, which prevents the threshold from ratcheting upward over a session.

3. **It inverts scrutiny allocation.** Small changes currently receive the least attention because they look trivial. Directing *more* suspicion at tiny diffs places vigilance where the scrutiny deficit actually is.

4. **It routes the legitimate complaint productively.** Some processes genuinely are heavyweight for trivial changes. "Complete it, then propose a fast-track rule" gets that fixed by the rule's owner instead of through accumulating unauthorized exemptions.

## Origin

An assistant was asked to bump a timeout value in a service config — a one-character change, 3 to 8. The project's process required running the config validation step before any commit, which the AI skipped as obviously unnecessary for "a single digit." The digit landed in the wrong unit field; the timeout went from 3 seconds to 8 milliseconds, and the service started failing every downstream call on deploy. The validation step that was too ceremonial for a one-character change would have rejected the config in under a second.
