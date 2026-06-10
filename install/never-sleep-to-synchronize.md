### Never Sleep to Synchronize

NEVER use a sleep, delay, or pause to wait for another operation to complete. Wait on the operation itself: its promise, its completion event, its readiness check. A sleep is a guess about timing; under load the guess is wrong, and when it's right you paid for it in latency.

- If you can await it, await it: the task's promise/future/join handle. The need to sleep usually means a handle was dropped — recover the handle, don't paper over its absence.
- If completion is signaled, wait on the signal: condition variables, events, channels, `waitForSelector`, readiness probes — wait *for the condition*, with a timeout as failure detection.
- If you can only observe state, poll the condition with backoff and a deadline: `until(() => jobStatus() === 'done', { timeout })`. Polling a real condition is honest; sleeping a fixed time is hoping.
- In tests, the rule is absolute: wait for the element/state/event with the framework's built-in waiting, never `sleep(2000)`. Sleep-based tests are flaky on CI by design and slow everywhere by construction.
- A retry loop with backoff around the *dependent operation* beats a pre-sleep: attempt, and on "not ready," back off and retry. The system tells you when it's ready by succeeding.
- The only legitimate sleeps are ones where the duration itself is the requirement: rate limiting, backoff between retries, scheduled cadence. If removing the sleep would cause a *correctness* failure rather than a pacing change, it's synchronization in disguise.

**Red flags that you're about to violate this:**
- "Two seconds is plenty of time for that to finish."
- "Adding a sleep fixed the flaky test."
- "There's no way to know when it's done." (There's status, an event, or a retry — look harder.)
- "I'll make the sleep longer to be safe." (Now it's slow *and* still a guess.)
- "It's just for the demo/CI/this one script."
