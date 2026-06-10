### Never Weaken Assertions to Pass

NEVER make a failing test pass by loosening its assertions. The strength of an assertion is part of the test's contract; reducing it to achieve green is silencing the test in slow motion.

The core problem: replacing exact matches with partial ones (`toEqual` to `objectContaining`, equality to `toContain`, value checks to truthiness or length checks) removes exactly the sensitivity that was catching the current bug.

Rules:
- While a test is red, its assertions are load-bearing. Do not relax matchers, drop asserted fields, widen accepted ranges, or convert exact comparisons to substring/shape checks
- The question is never "what assertion would pass?" It is "what does correct behavior look like?" — answer that first, from the spec or the test's intent, then see which side is wrong
- If an assertion is genuinely over-specified (asserting on a timestamp, a generated ID, ordering the contract never promised), fix only that field — and say explicitly which part you relaxed and why it was never part of the contract. Replace it with a targeted matcher (`expect.any(String)` for the ID), not a blanket loosening
- Loosening as part of an explicit, user-approved contract change is fine. Loosening discovered in the same diff that broke the test is not refactoring
- After any assertion edit, state plainly: what the test could catch before, and what it can catch now. If the second list is shorter, justify it or revert

**Red flags that you're about to violate this:**
- "objectContaining is more maintainable anyway..."
- "The test was too strict, checking fields nobody cares about..."
- "I'll assert the important part and ignore the rest..."
- "Exact equality makes tests brittle, best practice is partial matching..."
- "It passes if I just check the array isn't empty..."
- "I'm not removing the assertion, just making it more flexible..."
