---
title: Fail CI When Zero Tests Run
slug: fail-ci-when-zero-tests-run
category: ci-cd
tags: [universal, ci]
works_with: all
severity: high
one_liner: "Stops the AI from shipping pipelines where running no tests counts as passing"
---

# Fail CI When Zero Tests Run

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from configuring test steps that report success when they collected and executed nothing.

**[Copy-paste ready version](../../install/fail-ci-when-zero-tests-run.md)** — just the instruction block, no explanation.

## The Problem

"All tests passed" and "no tests ran" can produce the same green checkmark. A glob that matches nothing after a directory rename. A `testMatch` pattern that never fires because the new files end in `.test.tsx` instead of `.spec.ts`. A working-directory mixup so the runner scans an empty folder. A tag filter (`-m integration`) that selects an empty set after a marker was renamed. In several of these cases the tool exits zero — and where a tool is principled enough to exit non-zero on an empty collection (pytest's exit code 5), there's a flag to un-principle it: `--passWithNoTests`, `--allow-empty`, `|| true` on "no tests found" errors.

AI assistants reach for those flags by name. A pipeline fails with "No tests found, exiting with code 1"; the error message contains its own suppression instructions; `--passWithNoTests` appears in the next diff. The step is green. The test suite has zero members. Every PR from now on is "fully tested" by the empty set, which famously passes everything. This is the quietest possible way to delete a test suite — no test file was touched, coverage tools have nothing to compare, and the YAML change reads like configuration housekeeping.

The deeper trap is that empty runs are usually *symptoms*: the tests still exist, but a rename, move, or filter disconnected them from the runner. Passing-on-empty doesn't just tolerate the disconnection — it guarantees nobody is told about it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fail CI When Zero Tests Run

A test step that executes zero tests must fail. NEVER add `--passWithNoTests`, `--allow-empty`, or any equivalent flag, and never wrap a "no tests found" error in `|| true`. An empty test run almost always means the tests got disconnected from the runner — passing on empty is configuring CI to never mention it.

- When CI reports "no tests found," that is the bug to fix: check the glob/`testMatch` pattern against actual filenames, the working directory, the marker/tag filter, and recent renames. The tests are usually still there; the runner just can't see them.
- Configure runners to be strict where they aren't by default: keep pytest's exit-code-5 behavior (or use `pytest-error-for-skips`-style strictness), avoid `passWithNoTests` in jest config as well as CLI, and for runners that exit zero on empty, add an explicit count assertion.
- Belt-and-suspenders for load-bearing suites: have the test step emit the executed-test count and assert a floor, e.g. parse the JUnit XML or summary line and fail if `tests="0"` — or if the count dropped by an implausible fraction since the last run on the default branch.
- Sharded and filtered runs deserve special suspicion: a per-shard "this shard had no tests" is sometimes legitimate, but the *total* across shards must be nonzero — assert at the aggregation step, not per shard.
- The narrow legitimate case for pass-on-empty is a monorepo path-filtered job where "this package had no changes and has no tests to run" is expected. Even then, prefer skipping the job entirely (so it reports "skipped," which is honest) over running it and reporting "passed."

**Red flags that you're about to violate this:**

- "The error literally suggests --passWithNoTests; it's the documented fix."
- "This package doesn't have tests yet, so empty should pass for now."
- "The suite obviously has tests; a zero-test run can't really happen."
- "I'll allow empty runs to unblock the pipeline and fix the glob later."
- "Exit code 5 isn't a real failure; it's pytest being pedantic."

---

## Why It Works

1. **It distinguishes vacuous truth from verification.** "All tests passed" over an empty set is logically true and evidentially worthless; the rule forces the pipeline to report evidence, not logic.
2. **It treats empty-as-symptom.** Zero collected tests is nearly always a disconnection (rename, path, filter), so failing loudly routes attention to the actual bug at the moment it's one diff old and trivially bisectable.
3. **Count floors catch the partial version of the same failure** — a glob change that drops 900 of 1,000 tests still shows green-with-tests, and only a magnitude check notices the missing 90%.
4. **It anticipates the error message acting as an accomplice.** "No tests found" errors name their own suppression flag; pre-banning the flag by name beats the suggestion the assistant is about to read.

## Origin

A frontend repo migrated from `.spec.js` to `.test.tsx` naming during a TypeScript conversion, but the CI test step's glob still matched only the old pattern. The runner found nothing, and a previous "fix" had added `--passWithNoTests` during an unrelated bootstrap phase — so the step went green for six weeks while executing nothing, including through a state-management refactor merged on the strength of "all checks passing." The regression that finally surfaced in production had a failing test the whole time; CI had simply been configured to consider not-running-it a success.
