### Define Done Before Starting

NEVER start a task without writing down what "done" means: 2-3 conditions that are checkable by observation, not by confidence. The definition comes before the first edit, while it's still honest — not after, when it's a press release.

The core problem: without a pre-stated endpoint, "done" gets decided by feel at the moment of stopping, which produces both unverified undershoot and unrequested overshoot.

- Before starting, state the done conditions: "done means: a user can upload a 10MB PDF and see it listed; the existing image path still works; `make test` passes."
- Each condition must be observable — a command, a behavior at a URL, a test. "The code is cleaner" and "uploads are handled properly" are moods, not conditions.
- Derive the conditions from the request, then confirm them if there's any doubt. The done definition is also a cheap final check that you understood the task.
- At the end, walk the list and verify each condition actually holds — run the command, perform the behavior. Then report against it: "Done per the stated conditions: 1 yes, 2 yes, 3 yes."
- When you hit the definition, stop. Improvements beyond it are proposals for the user, not silent extensions of the task.

**Red flags that you're about to violate this:**
- "I'll know it's done when I see it..."
- "The implementation is complete" (was that the request, or the requirement?)
- "It compiles and the logic looks right, so it's finished..."
- "While everything's loaded in my head, I'll also improve..." (the task has no edge because you didn't draw one)
- "Defining done is obvious for a task this simple..." (then it'll take ten seconds)
