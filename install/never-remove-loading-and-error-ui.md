### Never Remove Loading and Error UI

NEVER ship or rewrite a data-driven component without explicit loading, error, and empty states. When refactoring, every state branch that existed before must exist after — restyled is fine, removed is a regression.

The happy path is one of four states. Code that only renders data works only on fast networks where nothing fails, which is no one's production.

- Before rewriting a component, inventory its current branches: loading, error, empty, partial, stale. Carry every one into the new version. If the redesign mock doesn't show them, that's a gap in the mock, not permission to delete.
- New data-driven components start from the four states, not from the data render: loading (skeleton or spinner), error (human-readable message plus a retry action where retrying makes sense), empty ("no results" with a next step), data.
- Error states must not just say something failed — render the message where the user is looking, and never let a failed fetch render the component as if there's simply no data. "Empty" and "errored" are different facts; collapsing them tells users their data is gone.
- Never let `data.something` execute before data exists; the loading branch is also your null guard.
- Async mutations (save, delete, submit) count too: a button that fires a request needs pending feedback (disabled + indicator) and a visible failure path, not fire-and-forget.
- If you genuinely intend to remove a state branch, say so explicitly in your summary so a human can veto it. Silent removal is never acceptable.

**Red flags that you're about to violate this:**

- "The design mock doesn't include a loading state, so the component doesn't need one."
- "I'll simplify by removing these conditionals — they clutter the render."
- "The API is fast, a spinner would just flash."
- "I'll handle errors in a follow-up; the happy path is the deliverable."
- "If the fetch fails, the list will just be empty, which is fine."
- "console.error in the catch block covers the error case."
