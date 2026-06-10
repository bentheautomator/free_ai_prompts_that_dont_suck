---
title: Don't Modernize Untested Code
slug: dont-modernize-untested-code
category: legacy-code
tags: [universal, legacy, testing]
works_with: all
severity: high
one_liner: "Stops idiom upgrades in untested code where silent behavior changes go unseen"
---

# Don't Modernize Untested Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from upgrading old idioms to modern ones in code that has no tests to catch the subtle behavior changes those upgrades smuggle in.

**[Copy-paste ready version](../../install/dont-modernize-untested-code.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant opens a 2012-era file and immediately wants to fix it: callbacks become async/await, string concatenation becomes templates, manual loops become map/filter chains, `var` becomes `const`. Each conversion is "equivalent" — except when it isn't. Async conversion changes error propagation timing and unhandled-rejection behavior. Loop-to-stream conversion changes evaluation order and what happens on the empty case. Strict equality swaps change how `null` and `0` flow through. These deltas are tiny, invisible in review, and only observable at runtime.

In tested code, the test suite catches the delta and the modernization is cheap. In untested code — which is most legacy code, that's why it's legacy — there is no net. The modernized version compiles, looks better, and behaves 0.5% differently in a way nobody discovers until an edge case hits production.

AI assistants do this by default because old idioms pattern-match as code smell, and the conversion feels like free value. But modernization is a behavior-preserving claim, and a behavior-preserving claim without tests is just a vibe.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Modernize Untested Code

NEVER upgrade idioms, syntax, or patterns in code that has no test coverage. Every "equivalent" modernization — callback to async, loop to stream, string format swap, equality operator change — carries small semantic deltas, and without tests those deltas ship silently.

Before modernizing anything:

- Check whether tests exercise the code you're about to touch. Look for test files referencing the module, then confirm the specific functions are actually covered, not just imported.
- If coverage exists, modernize and run the tests. That's the happy path.
- If coverage does not exist, you have two options: write characterization tests first (capture current behavior, including the weird parts, as assertions), or leave the idiom alone. "Leave it alone" is a fully acceptable outcome.
- Never bundle modernization into an unrelated change. If you're fixing a bug in an untested legacy file, fix the bug in the existing style.
- If the user explicitly asks for modernization of untested code, state plainly that there's no safety net and list the specific semantic risks of each conversion before proceeding.

Old syntax is not a defect. Wrong behavior is a defect. Untested modernization converts the first into the second.

**Red flags that you're about to violate this:**
- "This conversion is mechanically safe, it can't change behavior."
- "I'll modernize this file while I'm fixing the bug in it."
- "Nobody writes code like this anymore."
- "The linter suggests this change, so it must be equivalent."
- "It's a small file, I can verify equivalence by reading it."
- "Tests would be nice but the change is too trivial to need them."

---

## Why It Works

1. **It reframes modernization as a behavioral claim, not a style choice.** "Equivalent" becomes something the AI has to prove with tests, not assert from pattern knowledge.
2. **Characterization tests give the AI a productive outlet.** Instead of choosing between "modernize blind" and "do nothing," there's a third path that captures current behavior — weirdness included — before any rewrite.
3. **It names the specific semantic deltas** (error timing, evaluation order, null flow), so the AI stops thinking of conversions as text transformations and starts thinking of them as runtime changes.
4. **The bundling ban kills the most common entry point.** Most untested modernization arrives as a rider on a one-line bug fix, where nobody scrutinizes it.

## Origin

A maintenance fix in an old order-processing module came back with the surrounding callback chain helpfully converted to async/await. The conversion changed when a partial failure surfaced: previously the error fired before the confirmation email step, afterward it fired after. The module had no tests, the diff looked like an obvious improvement, and for six weeks a slice of failed orders sent customers confirmation emails for purchases that never completed. The bug fix itself was three lines and fine.
