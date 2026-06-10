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
