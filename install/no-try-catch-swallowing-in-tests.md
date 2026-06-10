### No Try/Catch Swallowing in Tests

NEVER wrap test logic in try/catch (or try/except) to keep an exception from failing the test. An unexpected exception in a test is the test working.

The core problem: a catch block in a test eats not just the crash you were avoiding, but assertion failures too. The test becomes unfailable and the runner reports it as passing.

Rules:
- No empty or pass-only catch blocks in tests, ever. No `.catch(() => {})` on awaited operations, no `except Exception: pass`
- If the code under test is *supposed* to throw, assert it precisely: `pytest.raises(SpecificError)`, `expect(fn).toThrow(SpecificError)`, `assertRaises` — these are assertions, not exception handling
- If an exception is unexpected, let it propagate. The traceback in the failure output is the diagnostic; swallowing it deletes the evidence and the failure simultaneously
- Do not catch-and-log either (`except Exception as e: print(e)`) — a printed error in a passing test is invisible
- A catch block that ends in `pytest.fail(...)` or rethrows after adding context is legitimate; one that lets the test return normally is not
- If you find yourself adding a try/catch to get past an error you don't understand, stop: report the error and what you tried instead

**Red flags that you're about to violate this:**
- "This throws sometimes in CI, I'll add defensive handling..."
- "Wrapping it in try/except makes the test more robust..."
- "I'll catch the error and just check the parts that work..."
- "The exception is from the environment, not the code, so it's safe to ignore..."
- "Good code handles exceptions, tests are code..."
