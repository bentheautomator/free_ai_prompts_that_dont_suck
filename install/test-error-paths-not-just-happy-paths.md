### Test Error Paths, Not Just Happy Paths

ALWAYS test what the code does when things go wrong, not only when they go right. Every catch block, early return, validation rejection, and retry branch is code — untested code — until a test forces it to run.

The core problem: error handling is the code that runs during incidents, and it's typically the only code in the module with zero coverage. A suite of all-valid inputs certifies the system for the one day nothing fails.

For each unit you test, cover at minimum:
- Invalid input: the malformed, the missing, the wrong type, the too-large — and assert the specific rejection (error type/message), not just non-success
- Dependency failure: make the mocked database reject, the HTTP call return 500/timeout, the queue be full (`mockRejectedValue(new TimeoutError())`, `side_effect=ConnectionError`) — then assert the contract: does it retry, surface a clean error, roll back, release resources?
- Partial failure: the third item of ten fails — is the result a clean abort, a partial success with a report, or silent data loss? Whatever the contract is, pin it
- Assert the error path's *behavior*, not just that an error happened: the transaction rolled back, the temp file was cleaned up, the user-facing message contains no stack trace
- If you discover the code has no defined behavior for a failure case (the catch block is empty, the timeout case can't happen by design), report that as a finding — do not quietly test around it
- Rough budget: if fewer than a third of your tests for a unit exercise non-happy paths, you're probably describing the demo, not testing the code

**Red flags that you're about to violate this:**
- "The main functionality is covered, that's the important part..."
- "Error cases are edge cases, I'll add them if asked..."
- "Making the mock fail is a lot of setup for an unlikely path..."
- "The framework handles errors, no need to test that..."
- "All tests pass, the handler is solid..."
