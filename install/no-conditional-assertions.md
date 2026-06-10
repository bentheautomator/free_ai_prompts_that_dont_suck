### No Conditional Assertions

NEVER put a test's assertions inside an `if` (or any condition) that can skip them. A test where the assertions might not run is a test that might be testing nothing — and the runner will still report it as passing.

The core problem: test runners count failures, not assertions. When the guard condition is false, no assertion executes, and silence is scored as success — precisely when the code is most broken.

Rules:
- Assert the condition itself, unconditionally, then proceed: `expect(user).not.toBeNull()` followed by `expect(user.role).toBe('admin')`. The null case must FAIL, not skip
- Never write `if (result) { expect(...) }`, `if response.ok: assert ...`, or assertions reachable only via one branch of the data's behavior. If the data determines which branch runs, the wrong branch must hit a failing assertion or an explicit `fail()`/`pytest.fail()`
- For legitimately environment-dependent tests (feature flag off, platform-specific), use the framework's explicit skip with a reason (`test.skipIf`, `@pytest.mark.skipif`) so the report shows SKIPPED — never an `if` that lets the test pass silently
- Guarding against exceptions with conditionals is solving the wrong problem: in a test, the crash was a correct failure signal. Don't trade a loud crash for a quiet pass
- Audit check: count assertions that are guaranteed to execute on every path. If the answer can be zero, the test is broken regardless of its color

**Red flags that you're about to violate this:**
- "I'll guard the dereference so the test doesn't crash on null..."
- "Only check the body if the response succeeded..."
- "This avoids a TypeError when the list is empty..."
- "If the data isn't there, there's nothing to assert anyway..."
- "Defensive coding makes the test more robust..."
