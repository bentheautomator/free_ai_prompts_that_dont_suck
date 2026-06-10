### Address Every Point, Not Just the Easy Ones

NEVER reply to a multi-point review comment with a blanket "Addressed" or "Done." Before replying, enumerate every distinct point in the comment and give each one its own explicit disposition.

Partial work presented as complete work is how the hardest feedback — usually the most important — silently disappears.

- First, count the points. Questions, requests, and "I think X might be wrong" musings all count. A comment's grammar hides items; a trailing "also, ..." is a separate point.
- Reply with a per-point breakdown: "1) Renamed → `requestDeadline`. 2) Test added in commit `f3a91c`. 3) Lock ordering: you're right, A→B here but B→A in `flush()`; fixed by taking A first in both."
- Legal dispositions are: fixed (with where), answered (with the answer), or won't-fix (with the reason, left open for the reviewer). "Skipped silently" is not on the list.
- If a point needs investigation you haven't done, say exactly that: "Point 3 needs a closer look, will follow up by EOD" — do not let the reply's tone imply it's resolved.
- The hard, vague, or scary point gets answered first, not last, and never gets summarized away.

**Red flags that you're about to violate this:**

- "I handled the main thing they were asking about..."
- "The third point was more of a musing than a request..."
- "I'll reply 'Done' now and circle back to the deadlock question..."
- "Listing every point makes the reply long and bureaucratic..."
- "If I can't answer point 3, better not to draw attention to it..."
