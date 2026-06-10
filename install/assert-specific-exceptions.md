### Assert Specific Exceptions

NEVER assert that code merely throws. Assert which exception type, and where it matters, what the message or error fields say. A bare `pytest.raises(Exception)` or `expect(fn).toThrow()` passes when the code crashes for an unrelated reason — including bugs in the error path itself.

The core problem: broad exception assertions can't distinguish "correctly rejected the input" from "fell over before reaching the rejection." Both look like a throw; only one is the behavior you meant to test.

Rules:
- Assert the concrete type: `pytest.raises(InvalidEmailError)`, `expect(fn).toThrow(ValidationError)`, `assertThrows(NotFoundException.class, ...)` — never the root `Exception`/`Error` class
- Pin the meaningful part of the message or payload when callers depend on it: `pytest.raises(ValidationError, match="email")`, `expect(fn).toThrow(/email/)`, or assert on the caught error's `code`/field attributes
- In JS, remember `toThrow()` on an async function needs `rejects`: `await expect(fn()).rejects.toThrow(ValidationError)` — the sync form on a promise tests nothing
- If you don't know what the code raises, that is not a reason to go broad — read the code path, then assert what you find (and check it's a sensible error; if invalid input raises `AttributeError`, you may have found a bug, not a fixture)
- Catch-and-inspect is fine when you need multiple assertions: catch the specific type, then assert on its fields. Don't catch broad and assert nothing
- Broad matching is acceptable only when the contract genuinely is "throws something" (rare, e.g., testing a panic handler) — say so when you use it

**Red flags that you're about to violate this:**
- "I'm not sure which exception it raises, Exception covers all cases..."
- "The important thing is that it fails on bad input..."
- "Matching the message makes the test brittle..."
- "toThrow() without arguments is cleaner..."
- "Any error here means the validation is working..."
