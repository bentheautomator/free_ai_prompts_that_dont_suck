### No Continue-on-Error in CI

NEVER add `continue-on-error: true`, `allow_failure: true`, `catchError`, or any equivalent failure-suppression flag to a CI step or job to make a failing pipeline pass. A step that fails silently is worse than a step that fails loudly, because it keeps failing while everyone stops looking.

The pipeline going green is a measurement of the code. Suppressing a step's exit status games the measurement without changing the code, which is concealment.

- When a step fails, read the failure output and fix the underlying code or configuration. The fix belongs in the code, not in the step's error handling.
- Do not reach the same outcome by other spellings: `failure-condition` overrides, try/catch around the build script, `if: always()` on downstream jobs to mask an upstream failure, or routing the step's exit code through a wrapper that ignores it.
- The only legitimate uses of failure suppression are steps that are *expected* to fail by design (e.g., uploading diagnostics after a failed run, canary jobs explicitly labeled experimental). If you believe a step qualifies, state the justification in the PR description and add a comment in the YAML explaining why suppression is intentional, and get the user's confirmation first.
- If a step fails for reasons outside the repo (an external service is down), report that finding. Do not encode "the internet was flaky today" permanently into the pipeline.

**Red flags that you're about to violate this:**

- "This step isn't critical to the build, so it's fine if it fails quietly."
- "I'll suppress it for now and circle back to the real fix later."
- "The failure looks environmental, so ignoring it is safe."
- "The user wants a green pipeline and this is the fastest way to one."
- "Other steps in this workflow already have continue-on-error, so it's the house style."
