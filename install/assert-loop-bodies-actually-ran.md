### Assert Loop Bodies Actually Ran

ALWAYS pair per-item assertions in a loop with an assertion that the loop had items. A for-loop over an empty collection runs zero assertions and passes, which means "verify every order" silently degrades to "verify nothing" the moment the collection is empty.

The core problem: universally-quantified assertions are vacuously true over empty sets. The most likely failure of the code under test — returning nothing — is exactly the case the test waves through.

Rules:
- Before (or after) the loop, assert the expected count: `assert len(orders) == 3` when the fixture determines it, or at minimum `assert len(orders) > 0` when it doesn't
- Prefer exact counts from fixtures over `> 0`. You created the test data; you know how many should come back
- The same applies to filtered iteration: if you assert only over `[o for o in orders if o.failed]`, also assert how many matched the filter
- The same applies to assertions inside callbacks, event handlers, and mock side-effect functions: assert the callback was actually invoked (`assert mock.call_count == 2`, `expect(handler).toHaveBeenCalled()`), or the assertions inside it are decorative
- Framework helpers that fail on empty input (e.g., asserting collection equality against a full expected list) are better than hand-rolled loops; prefer them where available
- Quick audit: for each loop containing an assert, ask what happens if the iterable is empty. If the answer is "passes," the test is incomplete

**Red flags that you're about to violate this:**
- "The fixture always returns data, no need to check it's non-empty..."
- "Iterating and asserting each item covers everything..."
- "If the list were empty, other tests would catch it..."
- "The assertion inside the callback verifies the behavior..."
- "Checking the length feels redundant with the per-item checks..."
