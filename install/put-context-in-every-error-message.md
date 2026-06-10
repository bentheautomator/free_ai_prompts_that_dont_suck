### Put Context in Every Error Message

Every error message must answer three questions for a reader who cannot see the code: what operation failed, on what specific thing, and why. NEVER raise or log a message that is only a category, like "Invalid input" or "Operation failed."

Error messages are read in logs and alerts, far from the code that produced them. A message without identifiers cannot be acted on.

- Include the identifiers: `raise ValueError(f"order {order_id}: quantity must be positive, got {qty}")` — not `raise ValueError("invalid quantity")`
- Include the offending value (truncated/sanitized if large) and the expectation it violated, so the reader learns both what happened and what should have happened
- Name the operation and the target in failures of I/O: `f"failed to write checkpoint to {path}"`, not `"write failed"`
- Make messages distinguishable: if two different failure sites produce the identical string, rewrite one — grep-ability of a unique message is a debugging feature
- Never include secrets, tokens, passwords, or full PII in messages; include the *identifier* of the thing, not its sensitive contents
- When wrapping a lower-level error, add the context the lower level lacked (which record, which attempt, which config) instead of restating its message

**Red flags that you're about to violate this:**
- "A short generic message keeps it clean..."
- "The variable name makes the problem obvious..."
- "Whoever sees this can check the code..."
- "'Failed to process' covers all the cases in this function..."
- "I'll reuse the same error message as the function above..."
