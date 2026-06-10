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
