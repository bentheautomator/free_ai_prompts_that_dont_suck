### Never Delete Failing CI Checks

NEVER delete, comment out, disable, or rename a CI job, step, or check because it is failing. A red check is a report about the code; removing the check changes the report, not the code.

The job of CI is to fail when the code is wrong. Making it stop failing without making the code right is concealment, not progress.

- When a check fails, read the logs, find the root cause in the code, and fix that. The workflow file is almost never where the bug is.
- Do not achieve deletion by other means: commenting out the job, removing it from a `needs:` chain so nothing depends on it, renaming it so branch protection loses track of it, or moving it to a workflow that never triggers. These are all the same violation.
- If a check is genuinely obsolete (tests a deleted feature, duplicates another job), say so explicitly, show the evidence, and let the user decide to remove it. Obsolescence is a human call.
- If a check is broken (the tool itself crashes, not the code under test), report the breakage with logs. A broken check gets fixed or explicitly retired — not quietly dropped in an unrelated PR.
- Never bundle check removal into a feature PR. If removal is ever approved, it gets its own commit with its own explanation.

**Red flags that you're about to violate this:**

- "This check has been failing for a while, so it's clearly not load-bearing."
- "The simplest way to get this pipeline green is to remove the failing job."
- "Nobody seems to maintain this check anyway."
- "I'll delete it now and we can re-add it once the errors are fixed."
- "The user asked for passing CI, and this is technically passing CI."
