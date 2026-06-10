---
title: Test Error Paths, Not Just Happy Paths
slug: test-error-paths-not-just-happy-paths
category: testing
tags: [universal, testing]
works_with: all
severity: high
one_liner: "AI test suites where every test feeds the code valid input and good news"
---

# Test Error Paths, Not Just Happy Paths

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents suites that only ever exercise the path where everything goes right.

**[Copy-paste ready version](../../install/test-error-paths-not-just-happy-paths.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "write tests for the upload handler" and you'll get a beautiful suite where every file is a valid PNG, every network call succeeds, every quota has room, and every test passes. What you won't get is the test where the upstream storage returns 503, where the file is 4GB, where the user's session expired mid-upload, or where the virus scan times out. Those paths — the `catch` blocks, the early returns, the retry logic, the cleanup code — ship with zero coverage, and they're precisely the code that runs when production has a bad day. Error-handling code is the least-executed, least-reviewed code in any system, which is why it's where the embarrassing outages live: the handler that was supposed to log-and-recover instead throws its own exception and takes the process down.

AI assistants skew happy because happy paths are the ones described in the function's name, docstring, and the user's request — "write tests for upload" parses as "test that uploading works." Failure paths require imagining hostile conditions nobody mentioned, and constructing them takes more setup (forcing a mock to reject, building a corrupt fixture) than the AI spends unless pushed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It reframes catch blocks as untested code.** The AI mentally files error handling under "robustness," not "behavior needing verification." Calling each catch block *code with zero coverage* puts it in the category the AI already knows demands tests.

2. **It supplies the failure menu.** The AI doesn't skip error tests out of refusal — it skips them because failures aren't in the prompt. A concrete checklist (invalid input, dependency failure, partial failure) replaces imagination with enumeration.

3. **It demands behavioral assertions on the error path.** "An error occurred" is a weak claim; "the transaction rolled back" is the contract. Specifying that distinction prevents the error tests that do get written from being decorative.

## Origin

A payment-webhook handler had fourteen tests, all green, all sending well-formed events that processed successfully. The first malformed webhook from a provider change hit the undefined-field path, where the error handler itself referenced a logger that didn't exist in that scope — crashing the worker, which the queue dutifully retried into a crash loop that blocked every payment behind it for hours. The catch block that failed had never once been executed before that night, by a test or anything else.
