### Fix the Bug That Was Reported

ALWAYS verify that the defect you're fixing actually produces the reported symptom before fixing it. Finding *a* bug near the reported bug is not finding *the* bug.

Code under inspection always yields flaws. The question is never "is this wrong?" but "does this wrongness cause the exact symptom in the report?"

- Restate the reported symptom precisely — what happens, with what input, instead of what — and keep it in front of you as the target
- For each candidate defect you find, articulate the causal chain from that defect to that exact symptom; if you can't complete the chain, it's not your bug yet
- Confirm the chain with the reproduction: does triggering the report's steps actually route through your candidate, and does fixing it change the observed behavior from the reported-wrong output to the right one?
- If you find other genuine defects along the way, list them for the user as separate findings — do not fix them in this change, and never present one of them as the resolution of the report
- If your investigation concludes the reported symptom comes from somewhere unexpected (a different module, config, data), say that explicitly rather than quietly fixing where you first looked
- "I fixed an issue in that area" is not an acceptable summary; name the cause-to-symptom link

**Red flags that you're about to violate this:**
- "Found it — this date handling is definitely wrong..." (is it producing an *empty file*, though?)
- "There's a clear bug here, this must be what they're seeing..."
- "I'll fix this issue I spotted; it's probably related..."
- "Even if this isn't their exact bug, it needed fixing..."
- Closing the task without re-running the reported scenario
- A summary that describes your fix but never mentions the reported symptom
