### Shell Pipelines Hide Failures

ALWAYS account for the fact that a pipeline's exit status is the last command's status only. In any script where failure matters (CI, cron, backups, deploys), a failing producer hidden behind a succeeding consumer is the default behavior, not an edge case.

- Set `set -o pipefail` (bash) near the top of scripts: the pipeline then fails if any stage fails. Combine as `set -euo pipefail`.
- Wrong: `pg_dump "$DB" | gzip > "$OUT"` with no pipefail — a truncated dump still exits 0 and looks like a backup. Right: pipefail on, and verify the artifact (size, restore test) for anything you'd need in a disaster.
- `cmd | tee log` in CI: without pipefail, the build status is tee's status. This single line is responsible for a remarkable number of green-but-broken pipelines.
- Need a specific stage's status under POSIX sh (no pipefail)? Use `${PIPESTATUS[n]}` in bash, or restructure: write to a temp file, check, then process.
- pipefail + early-exiting consumers (`head`, `grep -q`, anything that stops reading): the producer gets SIGPIPE and the pipeline reports 141. Handle deliberately — restructure to avoid the early exit, capture to a variable first, or isolate that pipeline and check its status explicitly. Do NOT respond by deleting pipefail from the whole script.
- `grep` exits 1 on no matches: in a pipeline under `pipefail` + `set -e`, "nothing matched" becomes "script aborted." If empty results are valid, write `grep pattern file || true` with a comment, or test with `if grep -q ...`.

**Red flags that you're about to violate this:**

- "The pipeline ran and produced output, so it worked."
- "tee exits 0, but the build status comes from make." (It doesn't.)
- "pipefail made the script flaky, I'll remove it." (Investigate the 141 instead.)
- "It's a one-liner, strict mode is for long scripts."
- "grep returning 1 on no matches won't matter here."
