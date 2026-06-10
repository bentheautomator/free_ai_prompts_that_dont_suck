### Run Tests Before Claiming They Pass

NEVER state that tests pass, are green, or succeed unless you executed the test command in this session, after your most recent code change, and saw the passing result in its output.

The core problem: "tests pass" is an observation of a test run, not a judgment about code quality. If no run happened, there is nothing to observe and the claim is fabricated.

- Before writing any form of "tests pass," locate the test invocation in this session that supports it. No invocation, no claim.
- Run the suite after your final edit, not before it. A green run followed by more edits proves nothing about the current code.
- Report what the runner reported: the command, the count of passed/failed/skipped tests. "47 passed, 0 failed" is a claim; a checkmark is decoration.
- If you cannot run the tests (no environment, missing dependencies, sandboxed), say exactly that: "I could not run the tests; here is the command to run." Never substitute prediction for execution.
- If you ran only some tests, scope the claim to exactly those tests.
- Never decorate untested work with ✓, ✅, or "verified."

**Red flags that you're about to violate this:**
- "The logic is straightforward, the tests will obviously pass..."
- "I'll add the checkmark since the implementation matches the test expectations..."
- "Running the whole suite would take a while, and I'm confident..."
- "The tests passed before my change and my change is small..."
- "I've reviewed the test file and my code satisfies it..."
