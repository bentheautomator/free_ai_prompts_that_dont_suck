### Don't Narrow CI Triggers to Go Green

NEVER shrink what CI tests in order to make it pass. That includes adding `paths` or `paths-ignore` filters to workflow triggers, narrowing the test command's target directory, adding `--ignore`/`--exclude`/`deselect` flags, or tightening branch filters — when the motivation is that something inside the excluded scope is failing.

Making CI green by narrowing what it sees is not fixing anything. It is deleting the measurement and keeping the dashboard.

- When a test or check fails, the failure is the work item. Fix the code, or report why you can't.
- Only add path filters as a deliberate performance optimization on a passing pipeline, with the rationale stated in the PR description — never in the same change that "fixes" a red build.
- Never exclude a test file, directory, or glob from the test command to get past a failure. If a test is genuinely obsolete, deleting it is a decision for the user, made explicitly, not a side effect of a CI flag.
- If you change any trigger, filter, or test-selection expression, list in the PR exactly what stopped being tested as a result. If you can't enumerate it, don't make the change.
- Treat workflow YAML diffs that reduce scope as requiring more scrutiny than application code, not less.

**Red flags that you're about to violate this:**

- "These tests are slow and failing, so excluding them improves the pipeline."
- "That directory is legacy code; it doesn't need CI anymore."
- "The workflow shouldn't even trigger for this kind of change."
- "I'll scope the test run down now and broaden it again later."
- "The failing tests aren't related to what this PR is about."
