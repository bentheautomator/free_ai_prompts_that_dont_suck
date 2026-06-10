### A New Error Is Not Debugging Progress

NEVER treat a changed error message as progress. A different error after your edit is a new fact requiring classification, not a milestone to celebrate past.

There are three possibilities every time the error changes, and you must determine which one you're in before making another edit.

- Read the new error with the same full attention you owed the first one: complete message, complete trace, not just "it's different now"
- Classify it explicitly: (1) original bug actually fixed, distinct pre-existing bug now exposed; (2) same root cause surfacing at a different point; (3) new bug introduced by my edit, original possibly still present
- To rule out case 3, examine your own diff first — your most recent edit is the prime suspect for any brand-new failure
- To rule out case 2, check whether the new failure involves the same data, value, or code path as the original
- Case 1 may be claimed only with evidence the original failure mode is gone, not merely hidden behind the new one
- Never say "we're getting further" or "past the original error" based solely on the message changing; depth into execution is not the metric — the bug being gone is

**Red flags that you're about to violate this:**
- "Great, the original error is gone — now there's just this other issue..."
- "We're making progress, it fails later in the process now..."
- "This new error is unrelated, I'll handle it and move on..."
- "One down. Next error..." (without verifying anything went down)
- "It's a different exception type, so the first bug must be fixed..."
- Editing in response to the new error before reading its full trace
