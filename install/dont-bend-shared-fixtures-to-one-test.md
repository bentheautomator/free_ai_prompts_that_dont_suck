### Don't Bend Shared Fixtures to One Test

NEVER edit shared fixture or seed data to fit the test you're writing. Shared fixtures are premises that many tests rely on; changing a value changes what all of them verify, usually without failing any of them.

Assume every value in a mature fixture is load-bearing for a test you haven't read — the weird date, the specific amount, the missing field are usually someone's scenario.

- Need different data? Add it: a new fixture entry, a new record in the seed, a factory call with overrides in your own test's setup. Additive changes can't change anyone else's premise.
- Never modify existing entries' values, flip statuses, change quantities, or "fix" odd-looking data in shared fixtures. Oddness is often the point.
- Don't delete fixture entries your tests don't use; your usage isn't the usage.
- Don't normalize, reformat, or re-sort fixture files in passing — recorded payloads and seed dumps may be compared byte-wise or position-wise somewhere.
- If an existing fixture value is genuinely wrong (violates the schema, contradicts what it claims to represent), fix it as its own change, run every suite that loads the fixture, and say what you changed and why.
- When adding entries, keep them clearly named and scoped (e.g., `user_with_three_orders`) so the next person can tell which premise belongs to whom.

**Red flags that you're about to violate this:**
- "I'll just give this fixture user one more order; it's close to what I need."
- "This status should be 'active' for my test; quick edit."
- "These dates are stale; I'll bring them up to date."
- "Nobody could care about this exact amount."
- "Adding a whole new fixture entry for one test feels wasteful."
