---
title: Don't Simplify Away Edge Cases
slug: dont-simplify-away-edge-cases
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: critical
one_liner: "Stops removal of odd-looking code that handles cases the AI never understood"
---

# Don't Simplify Away Edge Cases

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "simplifying" code by deleting branches and guards that handle real cases it didn't recognize.

**[Copy-paste ready version](../../install/dont-simplify-away-edge-cases.md)** — just the instruction block, no explanation.

## The Problem

The strangest-looking code in a mature codebase is usually the most expensive to have learned. The check for a negative quantity that "can't happen" exists because it happened. The special case for one specific merchant ID is a contractual obligation. The retry that sleeps exactly 1.1 seconds is tuned to a vendor's rate limiter. To an AI assistant doing a "simplification" pass, all of this reads as noise: unreachable branches, redundant guards, arbitrary constants. The model deletes them, the code gets shorter and genuinely more elegant, and the diff looks like pure win.

This is Chesterton's Fence at machine speed. The model can't distinguish "code I don't understand" from "code with no purpose," and its training rewards producing clean canonical implementations, so unexplained deviations from the canonical form register as flaws to remove. The deleted branch fires again weeks later, except now it doesn't exist, and the person debugging it has no idea the handling was ever there.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Simplify Away Edge Cases

NEVER delete a branch, guard, special case, or odd-looking constant during a refactor unless you can state specifically what case it handles and why that case no longer needs handling. "I don't see why this is needed" is a reason to keep it, not remove it.

Strange code in working systems is usually load-bearing: it encodes incidents, vendor quirks, and contractual exceptions that nobody wrote down anywhere else.

- Before removing any conditional, write down (to yourself, then in your summary) the concrete input that takes that branch. If you can't construct one, you don't understand the branch well enough to delete it.
- Treat these as presumed load-bearing: checks for "impossible" values, handling for one specific ID or customer or region, magic sleep durations and retry counts, fallbacks after operations that "can't fail," try/except around "safe" calls, and comparisons that look redundant (`x is None` and `not x` are different checks).
- "The tests still pass without it" is not evidence of deadness. Edge-case handling is exactly the code most likely to be untested, because it was added under fire.
- If you genuinely suspect dead code, don't delete it inside the refactor. Preserve it through the restructure, then list it separately as a removal candidate with your reasoning, and let the user decide.
- Use version control as a witness when available: a branch added in a commit mentioning a bug or incident is handling something real.
- Shorter is not the goal. Same behavior, better shape is the goal.

**Red flags that you're about to violate this:**

- "This condition can never be true."
- "This special case is clearly leftover from some old requirement."
- "Removing these three checks makes the function so much cleaner."
- "No sane input would ever hit this branch."
- "This fallback is paranoid; the call above can't fail."
- "Whoever wrote this was being overly defensive."

---

## Why It Works

1. **It inverts the burden of proof.** The model's default is "delete unless justified"; the rule flips it to "keep unless you can name the case and show it's obsolete," which is the only safe polarity for code you didn't write.
2. **The construct-an-input test is a real comprehension check.** A model that can't produce an input reaching the branch has just proven it doesn't understand the branch; the rule makes that proof block the deletion.
3. **The presumed-load-bearing list matches the actual hit list.** Impossible-value checks and magic constants are precisely what models delete most; pre-tagging them as suspicious-to-remove rather than suspicious-to-keep reverses the instinct where it does the most damage.
4. **The separate removal-candidate channel preserves legitimate cleanup.** Dead code does exist; routing deletions through a human keeps the win available without the silent risk.

## Origin

Asked to simplify a payment-webhook handler, an assistant removed a branch that re-checked the payload signature when a timestamp header was missing, reasoning that the gateway "always sends the header." One legacy integration didn't. For nineteen days, its webhooks were processed without signature verification, which the team discovered only during a security review, followed by an extremely long meeting.
