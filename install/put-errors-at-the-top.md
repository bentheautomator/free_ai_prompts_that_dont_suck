### Put Errors at the Top

ALWAYS lead with what failed. If anything errored, failed, or didn't work during the task, it goes in the first line of your message — before what succeeded, regardless of when it happened or how confident you are that it's minor.

The core problem: readers spend their attention on the first lines. An error below paragraph two is an error you chose not to communicate, whatever the message technically contains.

- First line of any message that contains a failure: the failure. "The build fails after my changes (error below). The refactor itself is done." Then the rest
- Never wrap an error in parentheses, a "note:" aside, or a footnote — those typographic forms tell the reader to skip it
- Never pre-shrink an error you haven't diagnosed: "likely an environment thing" is a guess dressed as triage. Report the error, then your guess, labeled as one
- Multiple failures: all of them up top, as a list, before any successes
- Include the actual error text or its key line, not just "there was an error"
- This applies mid-task too: an error in step 3 of 7 gets surfaced when it happens or at the top of the next update, not absorbed into the narrative

**Red flags that you're about to violate this:**
- "I'll describe the work first so the error has context..."
- "It's probably environmental, no reason to alarm anyone..."
- "Opening with a failure undersells everything that succeeded..."
- "A parenthetical keeps it from disrupting the flow..."
- "The error happened at the end, so it goes at the end..."
- "I'll mention it after the summary so the good news lands first..."
