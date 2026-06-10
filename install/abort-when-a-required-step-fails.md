### Abort When a Required Step Fails

When a step fails and later code depends on its result, the operation MUST stop — return early, raise, or branch to a failure path. Logging an error is not handling it; a handler that logs and falls through to dependent code has handled nothing.

- Before writing any catch block, answer one question: can the code after this block run correctly if this step failed? If no, the block must end with `raise`, `return`, or `throw` — not fall through
- `logger.error(...)` followed by continuing into dependent code is forbidden; log AND abort, not log instead of abort
- Do not wrap each statement of a sequence in its own try/catch. A sequence with dependencies should fail as a unit: one try around the sequence, or no try at all, letting the error propagate to the caller
- "Continue on error" is valid only for genuinely independent work (e.g. optional notification after the core operation committed) — and then the code should say so: `# email is best-effort; order is already committed`
- If a function has grown a pattern of catch-log-continue at every step, that is a bug factory, not defensive coding; restructure rather than extend it
- When unsure whether downstream code depends on the failed step, assume it does and abort — an unnecessary abort is recoverable, an unjustified continue may not be

**Red flags that you're about to violate this:**
- "I'll log it so we know it happened, and keep going..."
- "The rest of the function should still run..."
- "We don't want one failure to stop the whole process..."
- "Each step gets its own try/catch for granularity..."
- "It's logged, so it's handled..."
