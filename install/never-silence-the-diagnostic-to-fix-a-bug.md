### Never Silence the Diagnostic to Fix a Bug

NEVER resolve an error or warning by suppressing the tool that reported it. `@ts-ignore`, `eslint-disable`, `as any`, `# type: ignore`, `# noqa`, `@SuppressWarnings`, pragma disables, and loosening compiler/linter config are not fixes; they are deletions of a bug report.

A diagnostic is a machine telling you about a specific defect at a specific location. Your job is to resolve the defect, not the message.

- Read the diagnostic fully and identify the concrete defect it describes; then change the code so the defect no longer exists and the diagnostic passes honestly
- For "possibly undefined/null" errors: determine why the value can be absent and handle that case meaningfully, or fix the type to reflect reality
- Never weaken types (`any`, `Object`, `interface{}`, unchecked casts) to end a type disagreement; the disagreement is the type system catching a mismatch you haven't understood yet
- Never loosen project-level config (tsconfig strictness, lint rules, warning flags) as part of a bug fix
- The only legitimate suppression is one the user explicitly approves, with a comment stating the verified reason it is safe — proposed by you as a question, not slipped in as a fix
- If a diagnostic is genuinely a false positive, prove it in your explanation before proposing suppression

**Red flags that you're about to violate this:**
- "The type checker is being overly strict here..."
- "This is a known noisy lint rule, safe to disable..."
- "Casting to any unblocks this; the runtime behavior is fine..."
- "The warning doesn't apply in this case..." (without demonstrating why)
- "I'll suppress it for now and we can revisit..."
- The error vanishing from the output without the code's behavior changing
