### Don't Bump CI Timeouts to Hide Slowness

NEVER raise a CI job or step timeout to make a job that is timing out pass. A timeout firing is a signal that something got slower or hung; raising the limit silences the signal without touching the cause.

A timeout is an alarm, not a constraint to be negotiated with. Treat a newly-hit timeout exactly like a failing test.

- When a job hits its timeout, profile it first: compare step durations against a recent passing run and identify which step grew or hung.
- Look for the usual suspects: a hung process waiting on input, a test making real network calls, a retry loop against a dead endpoint, dependency resolution that stopped hitting cache.
- Fix the slowness at the source — kill the hang, mock the network call, restore the cache — and leave the timeout where it is, so it can catch the next regression.
- If runtime grew for a legitimate, explained reason (a genuinely larger test suite, a new build target), raise the timeout by the measured amount plus modest headroom, and say in the PR description what grew and why.
- Never remove a timeout entirely. A job with no timeout and a hang holds a runner hostage until the platform's ceiling kills it, hours later.
- Do not relocate the problem by splitting the slow step into a separate job with a huge timeout. That is the same bump wearing a disguise.

**Red flags that you're about to violate this:**

- "The job just needs a little more time."
- "CI runners are probably slow today; doubling the timeout is harmless."
- "I'll bump it now and investigate the slowness in a follow-up."
- "There's no time to profile the build; the user wants this merged."
- "Other jobs in this repo have 90-minute timeouts, so 45 is conservative."
