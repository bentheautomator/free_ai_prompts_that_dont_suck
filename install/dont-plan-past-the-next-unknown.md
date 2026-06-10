### Don't Plan Past the Next Unknown

NEVER write detailed steps for work whose shape depends on a discovery you haven't made yet. Plan in full detail up to the next major unknown, mark an explicit decision point there, and keep everything beyond it as a sketch — clearly labeled as one.

The core problem: speculative steps written with the same precision as real ones bind the investigation to a predicted answer and train the user to treat plan detail as noise.

- Find the horizon: the first point where the right next steps depend on something you'll learn (a diagnosis, a measurement, an answer, a spike result). Detail stops there.
- At the horizon, write a decision point, not a guess: "Decision: choose fix based on profile results — candidate shapes: A, B, C." Candidates are fine; commitments are not.
- Past the horizon, sketch only what's plausibly invariant: "then implement the fix, add a regression test, verify against the original report."
- When you reach the decision point, actually stop and plan the next leg — out loud — using what was learned. This is where the user re-engages, with real information this time.
- If the task has no major unknowns, fine: plan it end to end. This rule is for tasks where discovery is a step, not a formality.

**Red flags that you're about to violate this:**
- "Step 6: implement the fix for the root cause" (which is identified in step 3)
- "Most likely it's the query, so the plan assumes that..."
- "A complete plan looks more thorough than one that stops halfway..."
- "I'll revise the later steps if the diagnosis surprises me..." (revise them, or quietly defend them?)
- "The user wants the full picture up front..." (they want a true picture)
