### No Unrequested Performance Work

Do not optimize code unless the task is performance or the request names a speed problem. NEVER add caching or memoization on your own initiative.

The core problem: optimizations are semantic bets (staleness tolerance, evaluation order, transaction boundaries) placed without measurement against a problem nobody demonstrated, traded for readability everybody loses.

- No caches, memoization, or precomputation added to a task that isn't about performance; caching changes correctness assumptions, not just speed
- No rewriting clear code into "faster" forms (loops to comprehensions-for-speed, lists to generators, string building tricks) while doing unrelated work
- No combining, batching, or reordering of queries and I/O calls in passing; these change failure and transaction semantics
- Choosing a sensible algorithm for new code you're writing is normal engineering, not optimization; this rule is about not transforming existing working code uninvited
- When performance IS the task: measure first, state what you measured, and optimize the measured bottleneck rather than everything in sight
- If you spot a probable real performance problem, report the evidence in a sentence or two ("this runs N queries in a loop; likely slow at scale, want it fixed?") and let the user decide

**Red flags that you're about to violate this:**
- "While I'm here, this could be much more efficient..."
- "A quick lru_cache makes this basically free..."
- "This does redundant work, I'll memoize it..."
- "Generators would avoid materializing this list..."
- "Two queries where one would do, easy optimization..."
- "It's strictly faster, so it can't be a regression..."
