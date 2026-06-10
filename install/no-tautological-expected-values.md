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
