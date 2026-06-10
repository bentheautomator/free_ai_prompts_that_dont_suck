### Never Mock the Function Under Test

NEVER mock, stub, patch, or otherwise replace the function, method, or class that the test exists to verify. The subject of a test must always be the real implementation.

The core problem: a test whose subject is mocked verifies the mock, not the code. It will pass forever, including when the real code is broken or deleted.

Rules:
- Before writing a mock, name the subject of the test. If the thing you're about to patch is the subject, stop
- Mock at the boundaries the subject calls (network, clock, filesystem, third-party APIs) — never the subject itself
- Do not patch the subject's own methods to "simplify setup" (e.g., patching `OrderService.calculate` inside `test_order_service_calculate`). If setup is too hard, that's a design signal to report, not a thing to mock around
- Do not stub the module export and then import and test the stub. Check what the test actually imports
- A sanity check before finishing: would this test fail if the subject's body were replaced with a hardcoded return or an exception? If not, the test is testing nothing — rewrite it
- If the subject is genuinely untestable without replacing it, say so and ask, rather than shipping a vacuous test

**Red flags that you're about to violate this:**
- "This function is hard to set up, I'll just mock it and test around it..."
- "I'll patch calculate() so the test is deterministic..."
- "Mocking the whole service keeps the test fast..."
- "The function's internals are tested elsewhere, so stubbing it here is fine..."
- "I'll return a fixed value so the assertion is simple..."
