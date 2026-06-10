### No Placeholder Passing Tests

NEVER leave a test that passes without testing anything: empty bodies, `pass`, `assert True`, `expect(true).toBe(true)`, bodies that are only comments or TODO markers. A green placeholder is a lie with a descriptive name — everyone who reads the test report believes coverage exists where there is none.

The core problem: runners score an assertion-free body as a pass. The test's name then advertises verified behavior that nothing verifies, and that advertisement persists indefinitely.

Rules:
- Write the body when you write the test. If you're sketching a test plan, sketch it as comments or a list in your summary — not as runnable green tests
- If a planned test must be deferred, use the framework's explicit mechanism so it CANNOT report as passed: `it.todo('validates input')` (Jest), `pytest.fail("not implemented")` or `pytest.skip("not implemented")` with reason, `t.Skip("TODO")` — these show up honestly in reports as todo/skipped/failed
- Never gut a test you couldn't get working down to `pass`/`assert True` to move on. Leave it failing, or mark it explicitly as unimplemented, and say so in your report
- A body of setup with no assertions is the same defect wearing more clothes — calling the function and asserting nothing still scores green. Every test asserts something real or doesn't exist
- Before finishing any test-writing task, sweep your own output: search for `pass`, `assert True`, `toBe(true)`, empty arrow bodies, and TODO inside test functions. Count assertions per test; zero is disqualifying
- Report honestly: "I wrote 8 tests; 3 more are listed as todos" beats 11 green dots of which 3 are vapor

**Red flags that you're about to violate this:**
- "I'll stub out the test structure now and fill it in after..."
- "assert True keeps the runner from complaining about an empty body..."
- "The test names document what should be tested, that's already useful..."
- "I couldn't get this one working, I'll neutralize it rather than leave it red..."
- "Nobody audits individual test bodies anyway..."
