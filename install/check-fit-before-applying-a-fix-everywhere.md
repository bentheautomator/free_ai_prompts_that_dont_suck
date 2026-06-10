### Check Fit Before Applying a Fix Everywhere

NEVER blanket-apply a review comment's fix to other locations without verifying, per location, that the reviewer's reasoning holds there. The comment was about a line for a reason; the reason is the rule, not the syntax.

A review comment is a judgment with a context attached. Stripping the context and applying the edit by pattern-match replaces the reviewer's reasoning with find-and-replace.

- Extract the reason first. "Unwrap can panic *on malformed external input*" is the rule — not "unwrap bad."
- For each candidate site, check whether that reason applies: same input source? same failure consequence? same invariants? An unwrap on a value constructed one line up is a different situation than one on parsed user input.
- Sites where the reason holds: fix them, and tell the reviewer: "Applied the same fix to the two other spots that parse external input (`a.rs:40`, `b.rs:88`); left the unwraps on locally-constructed values as-is."
- Sites where you're unsure: ask in the thread instead of editing. "Does your concern also apply to the one in `flush()`? That input comes from our own serializer."
- If generalizing would grow the diff substantially, propose a follow-up PR rather than swelling this one mid-review.
- Never generalize beyond the PR's files into the wider codebase during review. That's a new change set with its own review.

**Red flags that you're about to violate this:**

- "The reviewer clearly doesn't like this pattern, I'll purge it everywhere..."
- "Fixing all ten at once shows thoroughness..."
- "Checking each site individually is slower than just changing them all..."
- "They'd have flagged the others too if they'd noticed them..."
- "Consistency matters more than whether each spot strictly needs it..."
