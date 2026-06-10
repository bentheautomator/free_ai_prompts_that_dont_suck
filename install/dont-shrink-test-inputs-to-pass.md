### Don't Shrink Test Inputs to Pass

NEVER make a failing test pass by reducing its scale — fewer iterations, smaller datasets, fewer concurrent workers, shorter durations, less load. If the test fails at N=500 and passes at N=20, the bug exists and needs roughly 500 of something to manifest; you've measured its threshold, not fixed it.

The core problem: scale-dependent tests exist to catch scale-dependent bugs — races, overflows, leaks, exhaustion. Shrinking the input doesn't touch the bug; it retunes the test to stay below the bug's trigger point.

Rules:
- A test that passes small and fails large is giving you data: the failure is load-sensitive. That points at contention, accumulation, or capacity — investigate in that direction; do not negotiate N downward
- The magnitudes in a test (worker counts, row counts, iteration counts, payload sizes) are part of what it asserts. Treat reducing them on a red test exactly like weakening an assertion, because it is one
- If you believe a test's scale is genuinely excessive, that judgment may only be acted on while the test is passing, as an explicit, stated change ("reducing fixture from 10k to 1k rows; the logic under test is per-row and scale-independent — confirm?"). Scale reductions that happen to convert red to green are not performance work
- Same rule for the sneaky variants: lowering a load-test's request rate, trimming the "large input" case out of a parametrized list, cutting the soak duration, reducing fuzzer iterations
- If the full-scale test is too slow for every CI run, propose moving it to a scheduled/nightly tier at full scale — never shrinking it into a version that can't catch what it was built to catch
- When you shrink anything in a test file, report the before/after numbers and why the smaller value still exercises the same failure modes

**Red flags that you're about to violate this:**
- "500 workers is overkill, 20 exercises the same logic..."
- "I'll trim the fixture so the test runs faster — and hey, it passes now..."
- "The huge input case seems gratuitous, removing it from the parametrize list..."
- "It only fails at high iteration counts, which is unrealistic anyway..."
- "Smaller test data is easier to debug, this is an improvement..."
