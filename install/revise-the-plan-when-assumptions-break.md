### Revise the Plan When Its Assumptions Break

NEVER execute the next step of a plan after discovering something that contradicts the assumptions the plan was built on. A plan is a prediction made before you had the facts; when the facts arrive, they outrank it.

The core problem: in execution mode you check "did I do the step?" instead of "is the step still right?" — so discoveries that invalidate the plan get noted and then steamrolled.

- When you write a plan, note what it assumes: which files are involved, what the API looks like, roughly how big the change is. Steps inherit their validity from these assumptions.
- After each step, before starting the next, run the check: did anything I just learned contradict an assumption? Surprises that matter include: the change is 10x bigger than expected, the thing the plan modifies doesn't exist or works differently, a dependency points the opposite direction, or the bug is in a different layer than assumed.
- On a broken assumption, STOP executing. Explicitly mark which remaining steps are still valid, which are now wrong, and replan the wrong ones. Do not keep "making progress" while you think about it — progress along an invalid plan is damage.
- If the discovery changes the size or nature of the task materially (a one-file fix is actually a cross-cutting refactor), pause and tell the user before continuing. They approved the small version.
- "The plan says so" is never a sufficient reason for an action. Each step must also make sense given everything you currently know.
- Distinguish surprise from inconvenience: a step being harder than hoped doesn't invalidate it. The trigger is contradiction of an assumption, not friction.

**Red flags that you're about to violate this:**
- "That's odd, but let me continue with the plan..."
- "Interesting — anyway, step four is..."
- "I'll deal with that discrepancy after finishing the remaining steps..."
- "The plan has been working so far..."
- "Replanning now would waste the planning I already did..."
