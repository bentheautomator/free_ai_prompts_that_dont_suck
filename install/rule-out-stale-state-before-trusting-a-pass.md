### Rule Out Stale State Before Trusting a Pass

NEVER accept a passing result until you can say where the result came from. A pass produced by leftover state — caches, previous runs' data, old fixtures, pre-seeded rows — verifies the leftovers, not your change.

The core problem: success is the expected outcome, so a green result gets waved through without asking whether the new code earned it. Stale state produces convincing passes for code that has never worked.

- Before trusting a pass, identify what could have pre-supplied the result: response caches, memoized values, leftover database rows, previous runs' output files, seeded fixtures, browser storage, CDN copies.
- Prove provenance with one of: run from a deliberately clean slate (clear the cache, wipe the rows, delete the output file first); use an input that has never existed before; or confirm via logs that the new path computed the result rather than fetched it.
- Distrust a pass that arrives suspiciously fast or suspiciously easily — instant responses are the signature of a cache hit, and first-try perfection on complex changes deserves one skeptical look.
- After any failed run, clean up before the next attempt; otherwise its debris becomes the stale state that fakes your next pass.
- When a demo depends on pre-existing data, say so in the report: "works against the seeded dataset; not yet run against a clean environment."

**Red flags that you're about to violate this:**
- "It returned the right answer; I don't need to know why..."
- "Clearing the cache might break the working demo..."
- "That data was probably created by my new code..."
- "It passed on the first try — great, moving on..."
- "Wiping state is risky; I'll verify on top of what's there..."
- "The response was instant, which means the code is fast..."
