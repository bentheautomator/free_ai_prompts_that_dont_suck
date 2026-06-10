---
title: Shell Pipelines Hide Failures
slug: shell-pipelines-hide-failures
category: language-pitfalls
tags: [universal, shell]
works_with: all
severity: high
one_liner: "Stops pipelines from reporting only the last command's exit status"
---

# Shell Pipelines Hide Failures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `cmd | tee log` and `curl | jq` pipelines from returning success when the command that actually mattered failed.

**[Copy-paste ready version](../../install/shell-pipelines-hide-failures.md)** — just the instruction block, no explanation.

## The Problem

A shell pipeline's exit status is the exit status of its *last* command. `pg_dump db | gzip > backup.gz` returns 0 if gzip succeeded — even if pg_dump died halfway through and the "backup" is a valid gzip file of half a database. `curl -s api/health | jq .status` reports jq's opinion, not curl's. `make 2>&1 | tee build.log` succeeds whenever tee succeeds, which is always, so the CI step goes green on a failed build. This is the inverse of how every other language treats errors in a sequence, and it specifically protects the failure of the command doing the real work.

There's a compounding trap: `pipefail` interacts with consumers that exit early. `cmd | head -1` makes `cmd` receive SIGPIPE when head closes the pipe, so with `pipefail` on, a perfectly fine pipeline can "fail" with status 141 — and the model's usual fix for that is to remove pipefail, restoring the original bug.

Assistants write bare pipelines because training-data shell is overwhelmingly interactive one-liners, where the human is watching the output and exit codes don't matter. Lifted into a cron job or CI step, the same line becomes a silent-failure machine.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It names the inversion.** "The command doing the real work is the one whose failure gets hidden" reframes pipelines from convenience to hazard, which changes where the model adds checks.
2. **It pre-handles the SIGPIPE backfire.** The predictable failure sequence is: add pipefail, hit status 141, remove pipefail. Explaining 141 up front keeps the fix from being reverted.
3. **It calls out `tee` and `grep` by name.** These two account for most real incidents in this class; specific commands are recallable where abstract rules are not.
4. **It ties verification to stakes.** "Verify the artifact for anything you'd need in a disaster" scopes the expensive advice to backups and deploys instead of everywhere.

## Origin

A nightly database backup ran `mysqldump | gzip | aws s3 cp - s3://...` for months of green checkmarks. The dump had been failing on a corrupted table since week three; gzip and the upload succeeded nightly, archiving a few hundred kilobytes of error preamble. The gap was discovered during an actual restore, which is the most expensive possible code review.
