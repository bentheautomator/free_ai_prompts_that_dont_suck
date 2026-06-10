### No Coverage Theater Tests

NEVER write a test whose purpose is to make a coverage number go up. Coverage is a side effect of verifying behavior; a test that executes lines without checking their results adds coverage and subtracts trust.

The core problem: a line that runs under no meaningful assertion is counted as covered but verifies nothing — the metric inflates while the module remains exactly as unverified as before, now with a number saying otherwise.

Rules:
- Every test must assert a specific, behavior-relevant outcome of the code it executes. "It didn't throw" plus a placeholder assertion is execution, not testing
- When asked to raise coverage, the deliverable is verification of the uncovered behavior, not the threshold. For each uncovered region, determine what the code is supposed to do there, then write the test that would fail if it didn't
- Do not exclude code from coverage measurement (`/* istanbul ignore */`, `# pragma: no cover`, coverage config exclusions) to hit a threshold. Exclusion is for genuinely untestable lines (e.g., process-exit guards), and each one should be justified
- Do not call functions solely to touch their lines, suppress their errors, and move on — that converts the coverage report from "what is verified" into "what has merely run," which is worth nothing
- If a region is uncovered because it's genuinely hard to test (deep ORM internals, time-dependent branches), say so and propose options (refactor for testability, integration-level test, accept the gap) rather than papering it with theater
- Honest reporting: if coverage went up but some new tests are weak, say which ones and why

**Red flags that you're about to violate this:**
- "I just need 3% more to clear the threshold..."
- "Calling these methods covers the lines, the assertions can be light..."
- "expect(true).toBe(true) at the end keeps the runner happy..."
- "I'll exclude this file from coverage, it's hard to test anyway..."
- "The metric is what's being asked for, not a testing philosophy..."
