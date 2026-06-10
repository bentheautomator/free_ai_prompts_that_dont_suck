### Never Swallow Exit Codes in CI

NEVER discard or override the exit code of a CI command to make a failing step pass. No `|| true`, no `|| echo`, no trailing `exit 0`, no `set +e`, no wrapping the command in a conditional that ignores the result.

A CI command's exit code is the only signal the pipeline has. Laundering it converts a working check into a decoration that runs, fails, and reports success.

- If a command fails in CI, fix the thing the command is checking. The exit code is the messenger, not the problem.
- Watch for accidental swallowing too: `cmd | tee log.txt` returns tee's exit code in plain sh; use `set -o pipefail` or capture the status explicitly. Multi-line `run:` blocks should start with `set -euo pipefail` so a mid-script failure cannot be shadowed by a later command succeeding.
- `|| echo "warning: X failed"` is not error handling. It is `|| true` with a guilty conscience.
- If a command is genuinely advisory (e.g., a metrics upload whose failure should not block merges), do not bury that decision in shell syntax. Surface it: tell the user, explain why it should be non-blocking, and let them approve before you change anything.
- Never swallow exit codes in test, lint, type-check, build, or security-scan commands under any circumstances. Those exit codes are the product.

**Red flags that you're about to violate this:**

- "This command's failure isn't related to what I was asked to do."
- "The step mostly works; the exit code is just noisy."
- "I'll log the failure instead of failing, so the information isn't lost."
- "Cleanup commands always fail in this environment, so or-true is pragmatic."
- "The pipeline needs to be green to merge, and this is one shell token away."
