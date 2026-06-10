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
