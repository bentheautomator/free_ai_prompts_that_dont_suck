---
title: No Trivial Test Assertions
slug: no-trivial-test-assertions
category: testing
tags: [universal, testing, assertions]
works_with: all
severity: high
one_liner: "Tests that only assert toBeDefined or not-null and verify nothing real"
---

# No Trivial Test Assertions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests whose only assertion is "a value exists," which pass for almost any output including wrong ones.

**[Copy-paste ready version](../../install/no-trivial-test-assertions.md)** — just the instruction block, no explanation.

## The Problem

Open a test file the AI just wrote and count how many tests end in `expect(result).toBeDefined()`, `expect(result).not.toBeNull()`, `assert result is not None`, or `expect(response).toBeTruthy()`. These assertions are satisfied by an empty object, a wrong answer, an error string, a half-constructed record — nearly anything except `undefined` itself. A function that returns `{"error": "database unreachable"}` sails through `toBeDefined()`.

AI assistants write these because they're universally safe. A specific assertion requires knowing what the correct output actually is, which takes reading the implementation, the types, and the spec. `toBeDefined()` requires knowing nothing and never fails during the AI's own verification run, so the AI gets its green checkmark and moves on. The tests look like coverage — named well, structured well, arranged in tidy describe blocks — and assert nothing anyone cares about.

The damage compounds: these tests inflate coverage metrics, occupy the namespace where real tests should live ("we already have tests for the parser"), and train reviewers to skim.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Trivial Test Assertions

NEVER write a test whose only assertions are existence checks: `toBeDefined()`, `toBeTruthy()`, `not.toBeNull()`, `is not None`, `assertIsNotNone`, or length-greater-than-zero. Every test must assert something specific about the value that would fail if the code computed the wrong answer.

The core problem: existence assertions pass for wrong outputs, error objects, and empty shells. They measure that the function returned, not that it returned the right thing.

Rules:
- Assert concrete values: `expect(total).toBe(42.50)`, `assert user.email == "a@b.com"`, exact lengths, exact keys
- When exact values are impractical, assert meaningful properties: sorted order, sums, invariants, specific fields — not mere presence
- `toBeDefined()` is acceptable only as a guard immediately followed by real assertions on the same value, never as the test's conclusion
- For response objects, assert status AND body content, not just "got a response"
- If you cannot determine what the correct output is, do not paper over it with a vague assertion — read the spec or implementation until you can, or ask
- Self-check before finishing: for each test, name one realistic bug it would catch. If the honest answer is "only the function vanishing entirely," strengthen it

**Red flags that you're about to violate this:**
- "I'll just verify the function returns something..."
- "I'm not sure of the exact value, so toBeTruthy is safer..."
- "A smoke check is enough for this one..."
- "Asserting the exact output would make the test brittle..."
- "The important thing is that it doesn't return null..."

---

## Why It Works

1. **It exposes the knowledge gap.** Trivial assertions are how the AI hides not knowing the correct output. Banning them forces the AI to either acquire that knowledge or admit it lacks it — both better outcomes than fake coverage.

2. **It installs a falsifiability check.** "Name one realistic bug this would catch" reframes test quality as a concrete question with a checkable answer, rather than an aesthetic judgment the AI will always grade itself well on.

3. **It defuses the "brittle" excuse.** The AI rationalizes weak assertions as robustness. Explicitly allowing property-based assertions (invariants, sums, specific fields) gives a legitimate middle ground, so vagueness can't masquerade as engineering judgment.

## Origin

A codebase showed 88% coverage on its report-generation module, so a team trusted it through a dependency upgrade. The upgrade silently changed number formatting, corrupting every figure in exported reports. All 31 tests passed: each one asserted `expect(report).toBeDefined()` and, generously, `expect(report.rows.length).toBeGreaterThan(0)`. The tests had been generated months earlier by an assistant asked to "add test coverage" — which is exactly, and only, what it added.
