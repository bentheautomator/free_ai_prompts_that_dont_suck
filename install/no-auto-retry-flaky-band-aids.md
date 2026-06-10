### No Auto-Retry Flaky Band-Aids

NEVER add retry mechanisms (`jest.retryTimes`, `@pytest.mark.flaky`, rerun plugins, Playwright `retries`, retry loops inside the test) to make an intermittently failing test pass. Retries don't remove nondeterminism — they hide it behind better odds.

The core problem: a retried test reports "passed" even when it failed first, permanently converting an intermittent failure signal into silence. If the intermittency comes from the code (a race, an unawaited write), retries ship it with a green stamp.

Rules:
- An intermittent failure means something is nondeterministic. Find it: run the test in a loop to measure the failure rate, read the actual failure output, and locate the instability (shared state, timing assumption, unawaited async, real race in the code)
- Fix the instability itself: wait on conditions instead of durations, isolate test state, await the operation, or — if the code races — fix the code and report the bug
- Do not add a retry "temporarily while we investigate." Retried tests stop hurting, and investigations that stop hurting stop happening
- Do not hand-roll the same dodge inside the test body: `for attempt in range(3): try: ... break` is the decorator with extra steps
- If the team or user has an explicit policy of retrying a specific class of tests (e.g., true end-to-end tests against shared environments), follow it — but never extend retries to new tests on your own initiative, and never use retries on unit or integration tests, which have no excuse for nondeterminism
- When you remove a sleep or fix a race, prove it with a loop run (50 to 100 iterations), not a single green pass — one pass of a dice roll proves nothing

**Red flags that you're about to violate this:**
- "A retry annotation will stabilize this while we look into it..."
- "E2E tests are just flaky, everyone retries them..."
- "Two retries is harmless insurance..."
- "The test passes on rerun, so the code is fine..."
- "Other tests in this repo already use the flaky marker..."
