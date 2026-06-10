---
title: Reproduce the Bug Before Touching Code
slug: reproduce-the-bug-before-touching-code
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI shipping fixes for bugs it never once observed failing"
---

# Reproduce the Bug Before Touching Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing a fix for a bug it has never actually seen happen.

**[Copy-paste ready version](../../install/reproduce-the-bug-before-touching-code.md)** — just the instruction block, no explanation.

## The Problem

Hand an AI assistant a bug report — "login fails for some users after the session expires" — and watch it skip directly to editing the session middleware. It read the description, imagined a plausible cause, and started fixing the imagined cause. At no point did it run the code, trigger the failure, or confirm that the bug it's fixing is the bug that exists.

This is backwards, and it's the default because reproduction is expensive (find the entry point, construct the failing input, run it, read output) while imagining a cause is free. The model has seen ten thousand session bugs in training data and pattern-matches to the most common one. Sometimes that gamble pays off. The rest of the time you get a confident fix for a hypothetical bug, a "fixed" label on a still-broken feature, and no way to even check — because without a reproduction, there is nothing to re-run afterward.

A bug you can't trigger is a bug you can't locate, can't fix with evidence, and can't confirm is gone. Everything downstream of a skipped reproduction is guesswork wearing a diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Reproduce the Bug Before Touching Code

ALWAYS reproduce a reported bug and observe the actual failure before modifying any code. No reproduction, no fix.

A fix written without a reproduction is a guess about a bug you imagined. The reproduction is also your only way to later demonstrate the bug is gone.

- First step on any bug report: find a concrete way to trigger the failure — a failing test, a script, a curl command, a specific input
- Run it and capture the real error output; the actual message frequently differs from the report's paraphrase
- Use the reporter's actual data, inputs, and steps where available, not a cleaned-up version you assume is equivalent
- If you cannot reproduce it, say so and investigate why (environment, data, timing) instead of fixing a theory; "couldn't reproduce, here's what I'd need" is a valid and honest result
- Prefer encoding the reproduction as a test that fails before your change, so it permanently documents the bug
- Only after watching it fail do you start forming theories about the cause

**Red flags that you're about to violate this:**
- "Based on the description, this is almost certainly the session timeout logic..."
- "I don't need to run it, I can see the bug from reading the code..."
- "Setting up a reproduction would take a while; the fix is simple..."
- "I'll fix the likely cause and the user can confirm..."
- "The report is clear enough to work from directly..."
- Editing code on a bug ticket before executing anything

---

## Why It Works

1. **It inverts the cost gradient.** The model defaults to free speculation over expensive reproduction. Making reproduction a hard precondition means the cheap path is no longer available, so the expensive-but-correct one actually happens.

2. **It corrects the report.** Bug reports paraphrase. The real error, real input, and real failing line routinely differ from the description, and reproduction is the only step that exposes the difference before a fix gets aimed at the wrong target.

3. **It creates the before/after measurement.** A fix without a prior failing run has no baseline; "it works now" is meaningless if it was never observed not working. The reproduction makes the later claim of a fix testable at all.

4. **It legitimizes "couldn't reproduce."** Giving the AI an approved honest exit removes the pressure to invent a fix just to have something to deliver.

## Origin

A developer reported that a CSV export "drops rows with special characters" and asked the assistant to fix it. The AI read the exporter, decided the encoding was the issue, and rewrote it to UTF-8 with BOM. The real bug, found a week later, was a regex that filtered rows containing commas inside quotes — nothing to do with encoding. Reproducing with the reporter's actual file would have shown the wrong rows disappearing in thirty seconds; instead the team shipped an encoding change that broke a downstream Excel import.
