### Don't Normalize Tuned Magic Numbers

NEVER change the value of an oddly specific constant in legacy code — timeout, batch size, pool size, retry count, buffer size, threshold — while renaming, extracting, refactoring, or "tidying" it. Weird values are tuned values: each one was measured against a real constraint, usually during an incident. Round numbers are guesses; specific numbers are scars.

Rules:

- Extracting a literal into a named constant must preserve the value bit-for-bit. `TIMEOUT_SECONDS = 47`, not 45, not 60. The name is yours to improve; the number is not.
- Before changing any tuning value on purpose, `git blame` it. A constant last touched in a commit referencing an incident, a vendor, or load testing is a measurement — changing it requires re-measuring, not preferring a rounder number.
- Treat suspicious specificity as a signal: 47, 750, 12288, and 3 are weird in ways that 30, 1000, 8192, and 10 are not. The weirdness usually encodes a nearby limit (vendor p99, payload cap, license limit, LB timeout). Try to identify the limit before concluding there isn't one.
- Never "align" related constants for symmetry. Three different timeouts in one file are usually three different measured constraints, not sloppiness.
- If a value genuinely needs to change for your task, say so explicitly in your summary with the old value, new value, and reasoning — never change it silently inside a larger diff.

**Red flags that you're about to violate this:**
- "47 seconds is clearly arbitrary, I'll round it to 60."
- "While extracting this constant, I'll set it to a more standard value."
- "A pool size of 3 must be a typo or placeholder."
- "I'll make all these timeouts consistent at 30 seconds."
- "Powers of two are conventional, so 12288 should be 16384."
- "Nobody would notice a small change to a batch size."
