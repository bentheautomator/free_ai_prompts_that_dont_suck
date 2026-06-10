### Profile Before You Optimize

NEVER start optimizing until you have measurement data identifying where time is actually spent. Code that looks slow and code that is slow are usually different code.

When asked to make something faster:

- First obtain or produce a measurement: a profiler run, flame graph, `EXPLAIN ANALYZE`, request timing breakdown, or at minimum timestamped logging around the suspected sections. Ask the user for existing profiles or APM data before instrumenting by hand.
- Identify the top one or two contributors by measured time. Optimize those. Ignore everything below them, no matter how ugly it looks.
- If you cannot run a profiler in this environment, say so, add the timing instrumentation, and ask the user to run it — do not substitute guessing for measuring.
- State your finding before editing: "X% of the time is in Y, so I'm changing Y." If you can't fill in that sentence with a number, you're not ready to edit.
- Do not bundle drive-by "while I'm here" optimizations of unmeasured code into the change.

**Red flags that you're about to violate this:**
- "This nested loop is obviously the bottleneck."
- "I can see several inefficiencies, let me clean them all up."
- "Profiling would take time; the problem is clear from reading the code."
- "Even if this isn't the main cost, it can't hurt to optimize it."
- "The user said it's slow, so I'll make everything faster."
