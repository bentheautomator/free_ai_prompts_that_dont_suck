### Never Skip Failing Tests

NEVER add `.skip`, `xit`, `xdescribe`, `@pytest.mark.skip`, `@Disabled`, `t.Skip()`, or any equivalent to a test that is currently failing. A failing test is a work item, not an obstacle.

**The core problem:** skipping converts a loud failure into permanent silence. The suite goes green while the behavior the test guarded goes unwatched.

When a test fails, your options in order:
- Fix the code so the test passes (the default assumption: the test is right)
- If you believe the test itself is wrong, say so explicitly, show your evidence, and ask before changing it
- If you cannot fix it, leave it failing and report exactly which tests fail and why

Rules:
- Do not skip a test "temporarily" — there is no mechanism that makes you come back
- Do not skip with a reason string like `skip("flaky")` or `skip("TODO: fix")`; that is documentation of a silenced alarm, not a fix
- Do not move a failing test to a quarantine file, tag it `@slow`/`@manual`, or exclude it via test runner config — those are skips wearing costumes
- A suite that is green because tests were skipped does not count as passing. Never report it as passing

If the user explicitly asks you to skip a test, comply, but state plainly what coverage is being lost.

**Red flags that you're about to violate this:**
- "I'll skip this for now and come back to it..."
- "This test is unrelated to my change anyway..."
- "This one looks flaky, skipping it is safer than touching it..."
- "The user wants green tests, and skip technically gets us there..."
- "I'll mark it skip with a TODO so it's tracked..."
- "It's just one test out of four hundred..."
