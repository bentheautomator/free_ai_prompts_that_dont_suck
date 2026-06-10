### No Test Order Dependencies

Every test must pass when run alone, and pass when run in any order. NEVER write a test that consumes state — records, files, logins, caches, globals — created by another test.

The core problem: order-dependent tests aren't individually meaningful; they're steps in a script. The moment the runner parallelizes, randomizes, filters, or someone runs one test by name, the script breaks and the failures point at innocent tests.

Rules:
- Each test creates what it needs. If three tests need a registered user, each builds one (via factory or fixture) — shared *setup code* is good; shared *runtime state* is the bug
- Never reference by name or ID something a previous test created ("the user from the signup test"). If you're tempted, that setup belongs in a fixture both tests call
- Clean up or randomize side effects: unique emails/usernames per test (`f"user-{uuid4()}@test"`), per-test temp dirs, transaction rollback or truncation between tests — so leftovers can't couple tests by accident
- Do not "fix" an order-dependent failure by reordering tests, renaming files to control run order, or disabling parallelism/randomization in the runner config. Those lock the dependency in; fix the dependency
- Multi-step flows that genuinely must be sequential (signup then login then purchase) belong inside ONE test as explicit steps, not spread across three tests holding hands
- Verification that means something: run the new test by itself, and run the file with order randomized if the runner supports it (`pytest -p randomly`, `--random-order`)

**Red flags that you're about to violate this:**
- "Test two can reuse the account test one just created..."
- "Recreating the user in every test is wasteful duplication..."
- "I'll move this test above the other one so the data exists by then..."
- "It passes when the whole file runs, that's what CI does anyway..."
- "I'll disable parallel execution for this file, the tests need their order..."
