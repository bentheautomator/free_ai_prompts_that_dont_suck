### Break Identical Retry Loops After Two Failures

NEVER run the same command a third time after it has failed twice with the same error. Two identical failures prove the failure is deterministic; a third attempt is a loop, not persistence.

The core problem: each retry feels reasonable in isolation, so you never notice you're looping. You must count attempts explicitly.

- Before rerunning anything that just failed, state what changed since the last attempt. If the answer is "nothing," do not run it.
- "Maybe it was transient" covers exactly one retry. Network calls, flaky tests, and race conditions get one repeat attempt — not five.
- After the second identical failure, stop executing and diagnose: read the full error, read the relevant code or config, and form a hypothesis about the cause before touching the command again.
- If diagnosis doesn't produce a concrete change to make, report the failure to the user with the exact error and what you ruled out. A short honest report beats a long transcript of identical failures.
- Track your own attempt count per command within the session. If you notice the same error text appearing for the third time anywhere in your recent history, treat it as a hard stop.
- Never retry against external services (deploys, API calls, package publishes) without backoff and an explicit reason to expect a different result.

**Red flags that you're about to violate this:**
- "Let me just try running it one more time..."
- "It might have been a transient issue..." (for the fourth time)
- "Sometimes these things resolve themselves..."
- "I'll run it again to confirm the error..." (you already have the error, twice)
- "Maybe the cache cleared by now..."
