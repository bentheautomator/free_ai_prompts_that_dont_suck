---
title: Keep CI Commands Matched to Local Dev
slug: keep-ci-commands-matched-to-local-dev
category: ci-cd
tags: [universal, ci]
works_with: all
severity: medium
one_liner: "Stops the AI from letting CI run different commands than developers run locally"
---

# Keep CI Commands Matched to Local Dev

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing bespoke command invocations into pipeline YAML that drift from what `make test` or `npm test` does on a laptop.

**[Copy-paste ready version](../../install/keep-ci-commands-matched-to-local-dev.md)** — just the instruction block, no explanation.

## The Problem

The repo has `npm test`, which runs `jest --coverage`. The CI workflow, written separately, runs `npx jest --ci --runInBand --testPathIgnorePatterns=e2e`. Three months and a dozen YAML tweaks later, nobody can tell you what CI actually tests, and the answer is provably not what developers test before pushing. The classic symptoms appear: "passes locally, fails in CI" tickets that burn hours on diff-the-environments archaeology, and its evil twin, "passes in CI, fails locally," which trains everyone to stop running tests on their machines at all.

Drift happens because pipeline YAML is where quick fixes go to hide. CI is flaky, so someone adds a flag in the workflow. A test misbehaves on the runner, so a filter gets appended — in the YAML, not in the test config, because the YAML is what was open in the editor. Each fix is local to CI, so the canonical command and the CI command diverge one flag at a time, and there is no force pushing them back together.

AI assistants accelerate this because writing a fresh command into the workflow is easier than discovering the repo's existing entrypoint. The assistant generating a workflow doesn't go read `Makefile` and `package.json` scripts first unless told to; it writes a plausible test invocation from training data. Plausible is exactly the problem — it works, it's green, and it's testing something subtly different from what everyone else runs.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep CI Commands Matched to Local Dev

CI must run the same entrypoints developers run locally. NEVER write a bespoke build, test, or lint invocation directly into pipeline YAML when the repo has a canonical command (`make test`, `npm run lint`, `./gradlew check`, a `justfile` or `tox.ini` target) — and never "fix" CI by adding flags in the YAML that local runs won't get.

When CI and laptops run different commands, "works on my machine" and "works in CI" become two unrelated facts, and one of them is always a surprise.

- Before writing any workflow step, find the repo's existing entrypoints: `Makefile`, `package.json` scripts, `justfile`, `tox.ini`, `composer.json`. The CI step should be that entrypoint, verbatim: `run: make test`, not a reconstruction of what you think make test does.
- If no canonical entrypoint exists, create one (a Makefile target or package script) and call it from both documentation and CI — don't let the workflow YAML become the only place the real command lives.
- CI-specific needs go through supported seams, not forked commands: environment variables (`CI=true`, which most tools already honor), a config file the tool reads everywhere, or an entrypoint parameter (`make test JOBS=2`). The command itself stays shared.
- When you need to change how tests run — add a flag, exclude a path, bump a timeout — change it in the shared entrypoint or tool config so laptops and CI move together. A flag added only in YAML is drift with a commit hash.
- If you find existing drift while working on the pipeline, flag it and propose consolidating to the shared entrypoint; don't extend the divergence.

**Red flags that you're about to violate this:**

- "I'll just write the jest command directly; it's clearer than indirection through make."
- "This flag is only needed in CI, so the YAML is the natural place for it."
- "The Makefile is crusty; I don't want to touch it."
- "CI needs slightly different behavior, so a slightly different command makes sense."
- "Copying the command from another repo's workflow is faster than reading this repo's scripts."

---

## Why It Works

1. **One entrypoint makes local runs predictive of CI runs.** The whole value of pre-push testing is forecasting the pipeline; divergent commands destroy the forecast and with it the habit.
2. **It routes environment differences through parameters instead of forks.** Real CI/laptop differences exist; expressing them as inputs to one shared command keeps a single source of truth with two configurations, instead of two truths.
3. **It blocks the drift mechanism, not just the state.** Drift accumulates via flags-added-in-YAML; requiring every behavioral change to land in the shared entrypoint removes the channel drift travels through.
4. **It forces repo discovery before generation**, countering the assistant's strongest default — emitting a plausible command from training data instead of the repo's actual one.

## Origin

A workflow's test step had accumulated `--testPathIgnorePatterns` entries over a year of CI-side quick fixes, while developers locally ran plain `npm test`. An engineer spent most of a sprint hunting a "CI-only" failure that turned out to pass in CI and fail locally — the test had been broken for months, CI had been configured to skip it, and every developer assumed their local failure was an environment quirk because the pipeline was green. The fix was one line of code and one very awkward retro about which command anyone thought was real.
