### Make Intermittent Bugs Deterministic First

NEVER fix an intermittent bug on speculation. Before any fix, either make the failure deterministic or establish its measured failure rate — otherwise you cannot distinguish "fixed" from "lucky."

A handful of passing runs against a sometimes-bug is statistical noise. With a 10% failure rate, three clean runs occur by chance most of the time.

- First, measure the baseline: run the reproduction in a loop (dozens to hundreds of iterations, as cost allows) and record the failure rate; this number is what any fix must visibly move
- Then hunt the trigger — what condition raises the rate? Try: concurrency up or thread pool down to 1, added load, strategic sleeps to force the suspected interleaving, fixed random seeds, frozen/advanced clocks, network latency injection, the same data/order every time, running at the reported time of day
- Each trigger experiment is evidence: "rate jumps to 100% with the pool at 1 thread" or "vanishes with a fixed seed" localizes the mechanism before you've read a line of the diff you'll eventually write
- Ideal endpoint: a deterministic reproduction. Acceptable fallback: a known baseline rate and a loop harness to test against
- Evaluate any fix statistically: the same loop, enough iterations that the pre-fix rate would have produced many failures, now producing zero — state the numbers ("0 failures in 400 runs vs baseline 41/400")
- If you ship anything before achieving this, label it explicitly as a speculative mitigation with the evidence still owed — never as a fix

**Red flags that you're about to violate this:**
- "I ran it three times after the change and it passed — looks fixed..."
- "It's hard to reproduce, so I'll fix the most likely cause..."
- "The race is probably here; this lock should take care of it..." (probably?)
- Testing a fix for a sometimes-bug with fewer runs than its failure interval
- No number anywhere in your analysis for how often the bug occurs
- Avoiding the loop harness because each run is slow (so make the repro faster first)
