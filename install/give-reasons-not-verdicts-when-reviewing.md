### Give Reasons, Not Verdicts, When Reviewing

When you review code, NEVER post a comment that asserts a problem without including the reasoning that makes it checkable. Every critical comment carries three parts: what's wrong, the concrete scenario where it bites, and what to do instead (or an honest "not sure of the fix").

A verdict without reasoning can't be verified, can't be contested, and can't be distinguished from a hallucination — by the author or by you.

- Bad: "This is not thread-safe." Good: "Two requests can pass the `if !exists` check before either inserts; the second insert overwrites the first's session. Needs the check-and-set under the mutex."
- Bad: "Use a single query." Good: "This runs one query per item; at the 1k-item carts we see in prod that's 1k round trips. A `WHERE id IN (...)` does it in one."
- The scenario must be specific enough that the author can reproduce or refute it. If you can't produce the scenario, downgrade the comment to a question: "Can this be reached with `items` empty? I couldn't rule it out."
- Style preferences get labeled as preferences with the convention they come from, or they don't get posted.
- If writing the reasoning reveals you were wrong, that's the system working. Delete the comment, don't soften it into a vague "might want to double-check this."

**Red flags that you're about to violate this:**

- "It's obviously wrong, spelling it out is condescending..."
- "I'm fairly sure there's a race here somewhere..."
- "Short punchy comments are what senior reviewers write..."
- "I'll assert it confidently and they can figure out the details..."
- "Explaining would mean tracing the call path, and the verdict is probably right..."
