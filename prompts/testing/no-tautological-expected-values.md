---
title: No Tautological Expected Values
slug: no-tautological-expected-values
category: testing
tags: [universal, testing, assertions]
works_with: all
severity: high
one_liner: "Tests computing the expected value with the same logic as the code under test"
---

# No Tautological Expected Values

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests that reimplement the production formula and then assert the code agrees with its twin.

**[Copy-paste ready version](../../install/no-tautological-expected-values.md)** — just the instruction block, no explanation.

## The Problem

Here's a test that can only fail if arithmetic stops working:

```python
def test_late_fee():
    expected = balance * 0.03 + max(0, (days_late - 5) * 0.50)
    assert calculate_late_fee(balance, days_late) == expected
```

The expected value was computed with the exact formula `calculate_late_fee` uses — the AI read the implementation, transplanted its logic into the test, and asserted that the function equals itself. If the formula has the wrong rate, the wrong grace period, or the wrong rounding, both sides are wrong identically and the test passes. It will pass for every input, forever, while telling you nothing. The loop-shaped variant builds expected lists by mapping the same transformation the code applies; the helper-shaped variant is sneakier — the test *imports the production function* (a formatter, a serializer, a rate table) to construct what it then asserts against.

AI assistants do this because the implementation is the most authoritative-looking source of the expected value in their context window, and mirroring it guarantees a passing test. It looks rigorous — there's real math in the test! — but the math and the subject share one brain, so no disagreement is possible.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Tautological Expected Values

NEVER compute a test's expected value using the same logic, formula, or production code as the thing under test. If both sides of the assertion share an error, the test passes — so they must not be able to share one.

The core problem: a test that mirrors the implementation verifies that the code equals a copy of itself. Wrong rate, wrong rounding, wrong branch — both sides agree, green forever.

Rules:
- Use precomputed literals, worked out by hand or from the spec: `assert calculate_late_fee(1000, 12) == 33.50` with a comment showing the arithmetic. A human-verifiable number is the whole point
- Do not import production helpers to build expectations: asserting `format_invoice(x) == format_invoice_expected_via_same_formatter(x)` tests nothing. The expected string should be typed out
- Do not build expected collections by applying the same `map`/`filter`/`sort` the code applies. Write the expected list literally, or assert independently checkable properties (totals, counts, specific elements)
- When the calculation is too complex for hand-derivation, use independently sourced cases: examples from the spec or RFC, known input/output pairs from documentation, values cross-checked with a different tool — anything whose correctness doesn't route through this codebase
- A duplicated-logic test is acceptable only as a differential test against a *genuinely independent* implementation (old system, reference library) — and label it as such
- Self-check: could a bug in the production formula make this test fail? If the test would inherit the bug, it's a tautology

**Red flags that you're about to violate this:**
- "I'll compute the expected value the same way the function does, to be accurate..."
- "Importing the formatter keeps the expected output in sync..."
- "Hardcoded numbers are magic values; deriving them is cleaner..."
- "The formula is right there in the implementation, no point re-deriving it..."
- "Building the expected list with a map keeps the test DRY..."

---

## Why It Works

1. **It inverts the "magic number" instinct.** The AI avoids literals because hardcoded values look like bad practice — in production code. Stating that a hand-derived literal is *the point* of a test expectation reverses an instinct that's correct everywhere else.

2. **It applies a shared-error test.** "Could a bug in the formula make this fail?" is a mechanical check for independence. A tautology answers no by construction, and the AI can detect that in its own draft.

3. **It names the import loophole.** Tests that call production formatters/helpers to build expectations are tautologies wearing modular clothing — the variant most likely to survive review. Banning the import pattern specifically closes it.

## Origin

An interest-accrual module had a respected test file: thirty cases, each computing expected interest with a tidy local formula and asserting the module matched. The formula in both places used 360-day year convention where the product contract specified 365. Every test passed; the module had been mis-accruing on every account since launch. An auditor caught it by checking three numbers against a pocket calculator — the only independent implementation that had ever been pointed at the code.
