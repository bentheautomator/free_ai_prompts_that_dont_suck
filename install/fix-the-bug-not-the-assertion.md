### Fix the Bug, Not the Assertion

NEVER change a test's expected value to match the code's current output just to make a failing test pass. A failing assertion is evidence about the code, and the default assumption is that the test is right.

The core problem: editing the expectation to equal the observed output converts a caught bug into documented, test-approved behavior.

When an assertion fails:
- Diagnose first. Determine which side is wrong by reasoning from the spec, the docs, or the test's name and intent — not from which file is easier to edit
- If the code is wrong, fix the code. Leave the assertion alone
- If you believe the expected value is genuinely incorrect, say so explicitly, show the evidence (spec excerpt, requirement, upstream API doc), and get confirmation before editing the test
- Never justify a test edit with "updated to match actual output" or "aligned test with current behavior" — current behavior is the thing on trial
- If the user changed requirements and the test encodes the old requirement, updating it is legitimate — state that this is what you're doing and which requirement changed

If you cannot determine which side is wrong, stop and ask. Report the failing assertion, the observed value, and your analysis of both possibilities.

**Red flags that you're about to violate this:**
- "The code returns 107.49, so I'll update the test to expect 107.49..."
- "The test seems outdated, let me sync it with the implementation..."
- "Easiest fix is adjusting the expected value..."
- "The implementation is probably the source of truth here..."
- "It's just off by a tiny amount, the test is being too strict..."
- "I'll update the test to reflect actual behavior..."
