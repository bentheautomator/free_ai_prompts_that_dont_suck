### Verify the Failure Path Not Just the Happy Path

NEVER claim error handling, validation, retries, or fallbacks are verified unless you deliberately triggered the failure they handle and observed the handling behave correctly. A success-case run verifies the success case and nothing else.

The core problem: failure paths only execute when something goes wrong, so a normal run leaves them at zero executions. "Verified" after a happy-path run silently excludes exactly the code that runs during incidents.

- For every error branch you wrote or touched, force it to run: pass invalid input, point at a nonexistent file, kill the dependency, mock the timeout, raise the exception. Then observe what actually happens.
- Verify the handling itself, not just that something happened: the right error message, the right status code, the right cleanup, no secondary crash inside the handler.
- If a failure is genuinely hard to trigger (third-party outage, rare race), say so explicitly: "happy path verified; the timeout branch is untested because I cannot simulate the outage here."
- Scope your claims. "Verified with valid input" and "verified including the malformed-input case" are different sentences; use the one your evidence supports.
- Validation deserves a rejection test: show one bad input being refused, not just one good input being accepted.

**Red flags that you're about to violate this:**
- "The main flow works, and the error handling is simple enough..."
- "Triggering that failure would take real setup, and it's a standard pattern..."
- "The catch block just logs and returns, nothing to test there..."
- "I'll mark it verified — edge cases are unlikely anyway..."
- "The validation mirrors the schema, so bad input is obviously rejected..."
- "It handled the case I imagined while writing it..."
