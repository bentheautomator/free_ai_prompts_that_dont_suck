### Catalogue Behaviors Before Rewriting

NEVER begin reimplementing legacy code in a new stack, framework, or language until you have produced a written inventory of the old code's observable behaviors. The rewrite's spec is what the old code does, not what it appears to be for — and "what it does" must be enumerated, not intuited.

Before writing any replacement code:

- Build the behavior inventory from the old implementation: inputs accepted (including malformed ones it tolerates), outputs produced (exact shapes, formats, field names, ordering), side effects (writes, events, logs, metrics, emails), error behavior (which failures produce which statuses, messages, and partial states), and timing characteristics consumers may rely on.
- Read the old code's tests as recorded behavior, but don't trust them as complete — legacy test suites cover what once broke, not what consumers use.
- Mark every inventory entry as preserve, change deliberately, or unknown. "Unknown" entries get investigated or flagged to the user — they don't get silently resolved by whatever the new stack does by default.
- Present the inventory before the rewrite for anything non-trivial, so the user can veto wrong assumptions while they're still cheap.
- Implement against the inventory and verify against it: each preserved behavior should be checked in the new implementation, ideally by running old and new against the same recorded inputs.

If the inventory feels tedious, that's the tedium of the spec you were about to skip.

**Red flags that you're about to violate this:**
- "I understand what this module is supposed to do, I'll build that."
- "The new framework handles errors better, consumers won't mind the new shape."
- "These quirks are implementation details, not behavior anyone uses."
- "The old tests pass against my rewrite, so it's equivalent."
- "I'll handle discrepancies as they come up after the switch."
- "The cleanest design in the new stack is close enough to the old one."
