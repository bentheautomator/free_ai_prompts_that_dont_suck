### Always Await Async Assertions

Every asynchronous operation in a test must be awaited before the test ends. An unawaited `expect(...).rejects`/`resolves`, an unreturned promise chain, or an unawaited coroutine means the test completes before the result exists — and a test that finishes before its assertions run passes unconditionally.

The core problem: the runner scores "function returned, nothing failed" as green. Asynchrony makes that state trivially reachable with zero assertions actually evaluated, and the broken version is one missing keyword away from the correct one.

Rules:
- `expect(promise).rejects...` and `.resolves...` return promises: ALWAYS `await` them, inside an `async` test. Unawaited, they assert into the void
- Never call the async function under test without awaiting it (or explicitly asserting on the awaited result). `const result = fn()` followed by assertions tests a pending promise object, not the outcome
- `.then()`/`.catch()` chains in tests must be returned or replaced with await; assertions inside an unreturned callback run after the verdict
- `forEach(async ...)` awaits nothing — use `for...of` with await, or `await Promise.all(items.map(...))`
- Python: a coroutine called without `await` never executes; use an async test (pytest-asyncio or equivalent) and await every coroutine. Treat any "coroutine was never awaited" warning in test output as a failing test, not noise
- Heed the runner's hints: Jest's "test finished but async operations are pending" class of warnings, unhandled rejection messages, open-handle reports — each is this bug announcing itself
- Verification that the test tests: break the code's behavior deliberately (make the function resolve when it should reject) and confirm the test goes red. An async test you've never seen fail has not yet earned trust

**Red flags that you're about to violate this:**
- "The rejects matcher handles the promise internally..."
- "The test passes, so the assertion must have run..."
- "I'll fire the calls in a forEach and assert after..."
- "That never-awaited warning is unrelated noise..."
- "Adding async/await everywhere is just ceremony for a one-liner test..."
