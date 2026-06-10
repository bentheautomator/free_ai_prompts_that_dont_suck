---
title: Flag Unrelated Bugs, Don't Fix Them
slug: flag-unrelated-bugs-dont-fix-them
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI silently fixing unrelated bugs it noticed instead of flagging them"
---

# Flag Unrelated Bugs, Don't Fix Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from silently fixing unrelated bugs it stumbles on, instead of surfacing them for a decision.

**[Copy-paste ready version](../../install/flag-unrelated-bugs-dont-fix-them.md)** — just the instruction block, no explanation.

## The Problem

While implementing your feature, the AI notices that a function two screens away has an off-by-one, or that a comparison uses `=` where it meant `==`, or that an early return skips cleanup. So it fixes it. Quietly. The diff for "add sorting to the results table" now contains an uncommented behavioral change to pagination, and nothing in the commit message, the PR description, or the AI's summary mentions it.

This is the most sympathetic form of scope creep — the AI might even be right that it's a bug — and that's what makes it dangerous. A "bug" identified by pattern-matching may be deliberate behavior: the off-by-one might compensate for an upstream quirk, the skipped cleanup might be load-bearing for performance, the weird comparison might handle a legacy data shape. The AI lacks the context to know, and fixing it silently means nobody with that context gets asked. The fix ships untested against whatever depended on the old behavior, hidden inside an unrelated diff where no reviewer is looking for it.

And when the silent fix is wrong, the regression appears in a part of the system the commit log says nobody touched.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Flag Unrelated Bugs, Don't Fix Them

When you notice a bug outside the task you were given, flag it. NEVER fix it silently inside an unrelated change.

The core problem: what looks like an obvious bug may be deliberate, compensating, or load-bearing behavior, and a silent fix ships that judgment call untested, unreviewed, and hidden where no one is looking for it.

- "Outside the task" means: the task neither asked you to fix this nor requires fixing it to work. If your change genuinely cannot function without the fix, say so explicitly and make the fix a visible, named part of the work
- Flag format: one or two sentences after completing the task. What you saw, where, why you think it's wrong. Example: "Note: `paginate()` in utils.py looks off-by-one for the final page; want me to fix that separately?"
- Apply this regardless of confidence; certainty that it's a bug does not grant permission to fix it, because the cost of silence is the same either way
- Never bundle the unrequested fix and mention it afterward; mentioning does not cure bundling, because the fix still ships inside a diff reviewers aren't examining for it
- If the user says fix it, fix it as its own change where possible, so it carries its own description and review

**Red flags that you're about to violate this:**
- "That's clearly a bug, I'll just fix it while I'm here..."
- "It's a one-character fix, not worth a separate discussion..."
- "Leaving a known bug in place would be irresponsible..."
- "I'll fix it and mention it in the summary..."
- "They'll obviously want this fixed, no need to ask..."

---

## Why It Works

1. **It attacks the certainty loophole.** The AI's permission structure is "if I'm sure, I may act"; stating that confidence doesn't change the cost of silence removes the loophole entirely.

2. **It defines "outside the task" operationally.** The blocking-bug case is the genuine exception, and defining it (cannot function without the fix, declared visibly) prevents the exception from swallowing the rule.

3. **It closes the mention-after-bundling escape.** "I'll fix it and note it" feels compliant; the rule explains why it isn't: the note doesn't move the fix out of an unexamined diff.

4. **It gives the flag a template.** A concrete two-sentence format makes flagging nearly free, so the AI's drive to be useful is satisfied by the cheap action instead of the risky one.

## Origin

While adding an export feature, an assistant "fixed" a date comparison that excluded the current day from a billing window, reasoning it was an off-by-one. It was intentional: the current day's records were incomplete until a nightly job ran, and the exclusion prevented double-billing. The fix shipped inside the export PR, invoices double-charged a day's usage for every customer in one region, and the refund run plus the apology emails cost more goodwill than any export feature ever earned.
