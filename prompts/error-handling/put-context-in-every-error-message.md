---
title: Put Context in Every Error Message
slug: put-context-in-every-error-message
category: error-handling
tags: [universal, errors]
works_with: all
severity: medium
one_liner: "AI raising 'Error occurred' with no identifiers, values, or operation names"
---

# Put Context in Every Error Message

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents error messages that describe the category of problem but not the actual problem.

**[Copy-paste ready version](../../install/put-context-in-every-error-message.md)** — just the instruction block, no explanation.

## The Problem

`raise ValueError("Invalid input")`. Invalid how? Which input? What was its value? What would a valid one look like? The message answers none of these, which means whoever reads it at 3 a.m. — in a log aggregator, stripped of surrounding code — gets to reconstruct all of it from scratch. The same goes for `throw new Error("Failed to process request")` and `log.error("Something went wrong")`. These are messages written for a reader who already knows everything.

AI assistants write context-free messages because at generation time, the context is sitting right there in the function. "Invalid input" feels complete when you can see that `input` is `user_id` and the check above it is a regex. But the message doesn't travel with the code; it travels to a log line, an alert, a bug report. The model optimizes for the message reading naturally in the diff, not for being actionable in isolation.

Multiply this by every error site in a codebase and you get logs where forty failures all say "Failed to fetch data" — same string, different bugs, no way to tell which code path or which record produced any of them.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It changes the imagined reader.** The model writes messages for someone looking at the code. Specifying "a reader who cannot see the code" — the actual log consumer — realigns what counts as a complete sentence.

2. **The three-question test is checkable at generation time.** "What operation, what thing, why" is concrete enough that the model can audit its own string before emitting it, unlike "be descriptive."

3. **It makes uniqueness a requirement, not a nicety.** Duplicate strings across failure sites are the single biggest obstacle to grepping logs back to code; banning them attacks a failure the model otherwise can't perceive.

4. **The PII carve-out removes the safety objection.** Without it, "don't log sensitive data" becomes the model's reason to strip *all* context; "identifier, not contents" keeps both rules satisfiable.

## Origin

During an incident, an on-call engineer found 14,000 occurrences of `Error: failed to sync record` in the logs — the only error string a recently AI-written sync service ever produced. It was emitted from six different code paths for four unrelated root causes. Determining *which* records had failed, and why, required adding context to every message, redeploying, and waiting for the failures to happen again. The fix took twenty minutes; the waiting took two days.
