---
title: Read CI Config Before Citing the Pipeline
slug: read-ci-config-before-citing-the-pipeline
category: context
tags: [universal, verification, tooling]
works_with: all
severity: high
one_liner: "AI promising 'CI will catch this' about a pipeline it never opened"
---

# Read CI Config Before Citing the Pipeline

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from making claims about what CI runs, checks, or catches without reading the workflow files.

**[Copy-paste ready version](../../install/read-ci-config-before-citing-the-pipeline.md)** — just the instruction block, no explanation.

## The Problem

"Don't worry, CI will catch any type errors before merge." Will it? This pipeline runs tests and a build — no typecheck step, because the team never added one. The AI's claim wasn't about this pipeline at all; it was about the platonic pipeline, the one most projects have, where lint and typecheck and tests all run on every PR. Claims like "CI runs the linter," "the pipeline deploys on merge," "integration tests run automatically" get made constantly about workflow files that were never opened.

These claims do real work in conversations: they justify skipping local verification ("CI will catch it"), shape risk assessments ("it's safe to merge, the pipeline gates it"), and inform process answers ("your deploy happens automatically"). When the claim is wrong, the safety net everyone leaned on turns out to be a drawing of a net. The unverified type error merges; the "automatic" deploy never existed and the release sits unshipped; the "gated" migration runs ungated.

The pipeline is fully specified in version-controlled files — `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/config.yml`. What CI does is not a matter of opinion or convention. It's a matter of reading.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reclassifies the claim.** "A claim about specific YAML, not about how pipelines usually work" cuts the inference from the platonic pipeline — the AI's actual source — and replaces it with a readable file.

2. **It distinguishes present from gating.** A check can exist, run, and still not block anything (`continue-on-error`, non-required jobs). Verifying "required, not just present" closes the gap most pipeline claims fall into.

3. **It targets triggers and path filters.** The subtlest wrong claims cite real jobs that don't run for *this* change; checking triggers catches the claim that's true in general and false right now.

4. **It severs the skip-local-checks justification.** "CI will catch it" is most often deployed to dodge verification; making that move conditional on a confirmed check converts the dodge back into a check.

## Origin

A reviewer asked whether a refactor was safe to merge late on a Friday. The AI: "yes — CI runs the full integration suite on every PR, and it's green." The repo's only workflow ran unit tests; the integration suite existed but was a manually-triggered workflow nobody had run in five weeks. The refactor broke a service contract the integration tests existed to verify, the breakage surfaced Monday in a partner's error logs, and the phrase "and it's green" was quoted in the incident channel with some bitterness.
