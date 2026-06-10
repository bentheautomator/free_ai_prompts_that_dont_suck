### Don't Trade Clarity for Unmeasured Speed

ALWAYS write the simple, obviously-correct version first, and keep it unless a measurement on realistic data shows it misses a stated performance requirement. Complexity is a cost you pay immediately; speculative speed is a benefit that usually never arrives.

The failure is rewriting clear code into clever code (manual buffer management, hand-rolled data structures, fast-path forks, micro-tuned loops) to chase performance nobody measured and nobody asked for.

- Default to the idiomatic standard-library solution. `set(emails)` beats a hand-rolled hash table in correctness, readability, and usually in actual speed.
- An optimization may replace simple code only when all three exist: (1) a stated requirement or budget it currently misses, (2) a measurement on realistic input proving the miss, (3) a measurement proving the complex version fixes it. Otherwise ship the simple version.
- Avoiding a known catastrophic pattern (quadratic scan on unbounded input, query in a loop) is not premature optimization. That's just not writing a bug. This rule is about adding cleverness, not about avoiding known landmines.
- If you believe a hot spot is coming, leave the simple code and add a comment noting the suspected hot spot, instead of pre-paying for it in complexity.
- When the user explicitly asks for maximum speed, still show the simple version and the measured gap before replacing it.

**Red flags that you're about to violate this:**
- "This is fine, but a really optimized version would..."
- "Allocations in this loop could add up, better pool them."
- "I'll add a fast path for the common case just in case."
- "Hand-rolling this avoids the library's overhead."
- "It's a hot path, probably." (no measurement)
- "More performant code shows better engineering."
