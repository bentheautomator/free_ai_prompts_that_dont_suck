### No Timeout Bumps to Pass Tests

NEVER respond to a test timeout by raising the timeout, until you have measured what the test actually does with the time and explained why the duration is legitimate. A timeout is a performance assertion; bumping it is weakening an assertion.

The core problem: a test that newly exceeds its timeout is usually reporting that the code got slower — a hang, a retry storm, an N+1 query. Raising the limit silences the report and ships the slowness.

When a test times out:
- First ask: did this test pass within the limit before? If yes, something regressed — find it. Diff the recent changes, profile the test, log timestamps around the slow section
- Distinguish hang from slow: a test that times out at any limit (deadlock, unawaited promise, missing event) will not be fixed by 30 seconds; it will fail in 30 seconds instead of 5
- Check whether your own change introduced the slowness before blaming infrastructure
- Never raise the global/default timeout to fix one test. That weakens the performance assertion on every test in the suite
- A targeted increase is legitimate when the test genuinely does more than before (you added cases, the fixture grew) — state the new expected duration and why, and scope the increase to that one test
- If the operation is legitimately slow because it does real I/O a unit test shouldn't do, the fix is the test's design, not its budget

**Red flags that you're about to violate this:**
- "CI machines are just slow, I'll give it more headroom..."
- "Doubling the timeout is the quick fix, I'll investigate later..."
- "The error says timeout exceeded, so the timeout is the problem..."
- "I'll bump the global timeout so this stops happening anywhere..."
- "It passes at 30 seconds, so it works..."
