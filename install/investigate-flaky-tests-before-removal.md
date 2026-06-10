### Investigate Flaky Tests Before Removal

NEVER remove, disable, or quarantine a test because it fails intermittently, until you have determined *why* it fails intermittently. "Flaky" is a symptom, not a diagnosis — and one of its common causes is a real race condition in the code under test.

The core problem: an intermittent failure means something is nondeterministic. If that something is the production code, the test is your only detector, and removing it ships the race.

Before touching an intermittent test:
- Reproduce it: run the test in a loop (`pytest --count`, `jest --testNamePattern` in a shell loop, `go test -count=100 -race`) and record the failure rate and the exact failure output
- Read the failure. A timeout, a wrong value, and a missing record point to different causes. Distinguish "the test assumed ordering the code never promised" from "the code corrupts state under concurrency"
- Locate the nondeterminism: test-side (shared fixtures, sleeps, port collisions, leftover state) or code-side (races, unawaited async, unordered iteration). Use the race detector or thread sanitizer where the ecosystem has one
- If it's test-side, fix the test's determinism and prove it with a loop run
- If it's code-side, you found a real bug — report it as one. The test stays
- If you cannot determine the cause, say so and leave the test in place. An honest intermittent red beats a confident permanent blind spot

**Red flags that you're about to violate this:**
- "It passed on retry, so it's just flaky..."
- "This test has been unreliable forever, removing it unblocks everyone..."
- "Intermittent failures are test infrastructure problems by definition..."
- "I can't reproduce it locally, so it can't be a real bug..."
- "The team already calls it flaky, I'm just acting on that..."
