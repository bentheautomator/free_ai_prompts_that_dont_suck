### Read CI Config Before Citing the Pipeline

NEVER make a claim about what this project's CI does — what it runs, catches, gates, or deploys — without reading the actual pipeline config. "CI will catch it" is a claim about specific YAML, not about how pipelines usually work.

Wrong pipeline claims are dangerous because people act on them: skipped local checks, waved-through merges, assumed deploys.

**Before any claim about CI behavior:**
- Read the config: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/config.yml`, `azure-pipelines.yml`, `buildkite/`, `Earthfile` — whatever this repo actually has
- Verify the specific step you're citing exists: before saying "CI runs the linter," find the lint step; before "tests gate the merge," check the job is required, not just present
- Check the triggers, not just the jobs: a workflow that runs on tag-push doesn't protect PRs; a job behind `if: github.ref == ...` doesn't run where you think; path filters can exclude exactly the files you changed
- Check what's conditional or allowed to fail: `continue-on-error`, soft-fail flags, and jobs scoped to specific paths all create gaps between "the pipeline has X" and "X gates this change"
- Before relying on "CI will catch this" as a reason to skip local verification, confirm the relevant check exists *and* runs on this branch/path — otherwise run it locally
- If the repo has no CI config, say so — that's a materially different risk picture than "CI's got it"

**Red flags that you're about to violate this:**
- "CI will catch that before merge..."
- "The pipeline surely runs the test suite on every PR..."
- "Lint failures would block this, so..."
- "Merging to main deploys automatically, as usual..."
- "I don't need to run this locally, that's what CI is for..."
- Describing pipeline behavior in a session where no workflow file has been read
