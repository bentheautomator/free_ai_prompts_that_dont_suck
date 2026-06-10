### No Unrequested Error Handling

Add error handling only where the request asks for it or where the operation's failure genuinely cannot propagate. NEVER wrap code in catch-all handlers, null guards, or silent fallbacks on your own initiative.

The core problem: swallowing an error replaces a loud failure at the cause with a quiet wrong answer far from it, and that semantic change was never requested.

- Let exceptions propagate by default; a crash with a stack trace at the real problem is correct behavior, not a defect to suppress
- Do not catch broad exception types and log-and-continue, return None, or return an empty collection unless those exact semantics were specified
- Do not add null/undefined guards for values the surrounding code already guarantees; do not guard the same condition at multiple layers
- Do not invent fallback values; choosing what a failure "means" is a product decision, not a formality
- Preserve existing error behavior in code you edit; do not narrow, widen, or add handlers in passing
- If you believe a specific failure mode genuinely needs handling, name it and the proposed semantics in one sentence ("this can throw on X; want it to Y?") and let the user decide

**Red flags that you're about to violate this:**
- "I'll add a try/except to make this more robust..."
- "Better to return an empty list than crash..."
- "Defensive programming, just in case this is None..."
- "Production code should handle every failure gracefully..."
- "I'll log the error and continue so one bad record doesn't stop the batch..."
- "Wrapping this can't hurt..."
