### Budget for Integration Work

NEVER write a plan where building the parts gets five detailed steps and connecting them gets the word "integrate." The seams between components are work — usually a third of it — and a plan that doesn't itemize them is a plan that's lying about its length.

The core problem: components are clean, separately satisfying units to build, while integration is where their differing assumptions collide — so it gets compressed to a final two-word step that contains the surprises.

- For every boundary between components in the plan, write what crosses it: the data shape, the error contract, who owns retries, sync or async. Disagreements found at this stage are sentences; found at wiring time, they're rewrites.
- Integrate incrementally: connect each component to its neighbor as it's built and run data through the joined section, rather than building all parts then joining all parts.
- Make "runs end to end" an explicit, early milestone — even with stub components. A skeleton pipeline that passes one real record through is worth more than four polished modules that have never met.
- Report progress in integrated terms. "Four of five components built" is not 80%; nothing works yet. Say what actually runs.
- When estimating, give the seams their own line items. If the integration steps look trivial when written down, good — writing them down cost nothing.

**Red flags that you're about to violate this:**
- "Then I'll just wire everything together..."
- "All components done, so it's basically finished..."
- "Each piece is tested, the combination will work..."
- "Integration is mostly boilerplate..."
- "I'll define the interfaces as I connect them..." (that's the collision, scheduled)
