---
title: Test the Spec, Not Current Behavior
slug: test-the-spec-not-current-behavior
category: testing
tags: [universal, testing]
works_with: all
severity: high
one_liner: "After-the-fact tests that enshrine whatever the code happens to do"
---

# Test the Spec, Not Current Behavior

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests whose expected values were copied from the code's own output, bugs included.

**[Copy-paste ready version](../../install/test-the-spec-not-current-behavior.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "add tests for the pricing module" and watch its method: it runs the function with some inputs, observes the output, and writes assertions expecting exactly that output. `calculatePrice(3, 'EU')` returned `41.99`? Then `expect(calculatePrice(3, 'EU')).toBe(41.99)` it is. The test will pass — it's guaranteed to pass, that's where the number came from. If the function has a bug and should return 43.99, the suite now contains a passing test asserting the bug is correct, plus a tripwire against anyone fixing it.

This is the test-generation equivalent of grading your own exam by copying your answers into the answer key. The AI does it because deriving expected values independently is genuinely hard: it requires reading the spec, the docs, the ticket, or doing the math by hand. Observing output requires none of that and produces tests that all pass on the first run — which looks like competence.

There's a legitimate cousin: characterization tests, written deliberately to pin down legacy behavior before a refactor. The difference is intent and labeling. The failure mode is doing characterization testing by accident, everywhere, and calling it test coverage.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Test the Spec, Not Current Behavior

NEVER derive a test's expected value by running the code and copying its output. Expected values must come from an independent source: the spec, the docs, the ticket, a worked example, or arithmetic you did yourself.

The core problem: a test whose expectation was copied from the implementation can only confirm the implementation agrees with itself. It is incapable of catching a bug, and it actively defends existing bugs against fixes.

Rules:
- For each expected value, be able to answer: how do I know this is correct, *other than* the code producing it? If the only answer is "that's what it returned," you don't have a test yet
- Work examples by hand. If the function computes tax, compute the tax yourself for the fixture inputs and assert your number
- When the spec and the code disagree, you have found a bug, not a test problem. Report it; do not assert the code's answer
- If no spec exists and you genuinely cannot derive the correct value, you may write a characterization test, but you must label it as one (in the test name or a comment) and tell the user: "these tests pin current behavior, which I could not independently verify"
- Suspicious sign in your own output: every test you wrote passed on the first run and none required you to understand the domain

**Red flags that you're about to violate this:**
- "I'll run it once to see what it returns, then assert that..."
- "The function gave 41.99, so that's the expected value..."
- "These tests document the current behavior, which is what tests are for..."
- "I can't easily compute this by hand, but the code's answer looks plausible..."
- "All my new tests pass immediately — great sign..."

---

## Why It Works

1. **It imposes an independence requirement.** The core defect is circularity: expectation and implementation sharing one source. Demanding a second source ("how do I know, other than the code?") is a direct structural fix the AI can self-audit.

2. **It inverts a false success signal.** "All my tests passed first try" feels like quality to the model. Flagging it as a suspicious sign recalibrates the AI's own sense of when it's doing well.

3. **It separates the legitimate cousin.** Characterization testing is real and useful; banning it outright would make the rule brittle. Requiring the label and the disclosure preserves the practice while killing the accidental version.

## Origin

A team asked for tests before refactoring a shipping-cost calculator. The assistant generated forty tests by exercising the calculator and asserting its outputs; all passed. The refactor proceeded, and the new implementation was checked against those tests — which faithfully preserved a unit-conversion bug that had been overcharging one region for months. The refactor was the one chance to catch it cheaply, and the test suite spent that chance certifying the bug.
