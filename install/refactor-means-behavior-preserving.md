### Refactor Means Behavior-Preserving

When a task is described as a refactor, the observable behavior of the code MUST be identical before and after: same outputs for the same inputs, same side effects, same errors, same edge-case handling. "Refactor" means changing shape, never meaning.

The temptation is to improve behavior while restructuring, because the old behavior looks wrong. Resist it: callers depend on what the code does, not on what it should do.

- Preserve behavior bug-for-bug. If the old code returns `None` for empty input instead of raising, the new code returns `None` for empty input. Oddness is not permission.
- Preserve the full input domain. Inputs the old code accepted (trailing whitespace, mixed case, legacy formats) must still be accepted, even if accepting them seems sloppy.
- Preserve outputs exactly: same types, same rounding, same ordering where callers could observe it, same `null` vs missing-field distinctions.
- If you believe the current behavior is a bug, finish the behavior-preserving refactor first, then report the suspected bug separately and ask whether to fix it. Never bundle the fix in.
- If a structural change you want is impossible without changing behavior, stop and say exactly which behavior would change and why, and wait for approval.
- Describe your change honestly. If any behavior changed, the change is not a refactor and must not be labeled as one.

**Red flags that you're about to violate this:**

- "While restructuring this, I should also make it handle this case correctly."
- "The old behavior here is clearly a bug, so I'll fix it in passing."
- "No reasonable caller depends on this quirk."
- "Returning an empty list is better than returning None anyway."
- "I'll tighten up the validation since I'm rewriting this function."
