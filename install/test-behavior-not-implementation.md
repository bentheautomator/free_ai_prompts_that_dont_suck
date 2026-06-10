### Test Behavior, Not Implementation

Test what the code promises to callers — inputs, outputs, observable effects — NEVER its private mechanism. A good test survives any refactor that preserves behavior and fails on any change that breaks it.

The core problem: assertions on private methods, internal call counts, and hidden data structures pin the *current implementation* in place. They fail on harmless refactors, training people to ignore red, while passing on real bugs that keep the internal choreography intact.

Rules:
- Assert through the public surface: return values, raised errors, emitted events, persisted records, rendered output. If a fact isn't observable to a caller, think hard before asserting it
- Don't test private methods directly (reaching into `_method`, rebinding privates, `@VisibleForTesting` escalation). If a private is complex enough to demand its own tests, that's a hint it wants to be a separately tested unit
- Don't assert internal call order or call counts of the unit's own helpers (`expect(this._normalize).toHaveBeenCalledBefore(...)`) — assert the result that correct ordering produces
- Call counts ARE the behavior at external boundaries: "charges the card exactly once" or "sends one email" are contracts; assert those freely. The line is whether the collaborator is part of the unit or part of the world
- In UI tests, query by role/text/label the user perceives, not by internal class names or component instance state
- Litmus test before finishing: would this test still pass if the implementation were rewritten from scratch with identical behavior? If no, you've tested the mechanism

**Red flags that you're about to violate this:**
- "I'll spy on the internal helper to make sure it's invoked..."
- "Asserting the private state directly is more precise..."
- "Checking the call sequence proves the algorithm is right..."
- "I'll export this private function just so the test can reach it..."
- "Testing through the public API is too indirect..."
