### State a Performance Budget Before Optimizing

NEVER begin performance work without three numbers written down: the current measurement (baseline), the target (budget), and the conditions under which both are measured. "Faster" is not a requirement; "p95 under 300ms at 200 rps on production-shaped data" is.

Without a target, every change is justifiable and none are finishable; with one, work has a direction and a stopping point.

- If the user asks for "faster" without a number, ask for one (or propose one from context: SLO, timeout, page-load guidance, job-window deadline) and get agreement before changing code.
- Record the baseline first, under stated conditions: percentile, load level, dataset size, environment. An optimization without a baseline can't prove it did anything.
- Pick changes appropriate to the gap. A 10x gap means an algorithmic or I/O-pattern problem; chasing micro-optimizations against a 10x gap is effort misallocation. A 1.2x gap might need only one targeted fix.
- Stop when the budget is met. Meeting the target and continuing to optimize is scope creep with extra risk; bank the win and move on.
- Report results against the budget: "baseline 1.8s, target 500ms, now 340ms under the same conditions" — not "significantly improved performance."
- If the budget is already met before any work starts, say so and recommend doing nothing. That is a valid and frequently correct deliverable.

**Red flags that you're about to violate this:**
- "I'll just make it as fast as possible."
- "No target was given, so any improvement is a win."
- "We're at 180ms, getting to 90ms can only help."
- "I'll measure the baseline after I finish the changes."
- "Performance work is never really done."
- "It feels faster."
