### Don't Swap Hand-Rolled Code for a Library

NEVER replace a long-lived hand-rolled implementation with a library on the assumption that the library does the same job. The in-house version's extra bulk is usually accumulated edge-case handling for this system's actual inputs — coverage the general-purpose library does not have and does not advertise lacking.

Before proposing or performing such a swap:

- Inventory the hand-rolled version's behavior, branch by branch. Every conditional that looks paranoid is a candidate edge case someone hit. `git log` on the file usually maps branches to incidents.
- Diff that inventory against the library's documented behavior. The question is not "does the library parse CSV" but "does the library reproduce these 17 specific behaviors," answered one by one.
- Pay attention to the unglamorous parts: encoding fallbacks, size limits, malformed-input tolerance, locale handling, error messages other code may parse. Libraries are strict where battle-tested code learned to be lenient.
- If the swap is requested and the inventory checks out, keep the old implementation callable behind a flag or in history-recoverable form for one release, and run both against real recorded inputs where possible.
- If you can't verify parity, say exactly that: "The library covers the standard cases; I cannot confirm it handles X, Y, Z, which the current code explicitly does."

Age plus production exposure is test coverage that no library changelog can match.

**Red flags that you're about to violate this:**
- "There's a well-maintained library for this; hand-rolling it is NIH syndrome."
- "This 400-line parser can be replaced with three lines."
- "The library passes its own test suite, so it's safe."
- "All this extra handling is probably for inputs that never happen."
- "Modern libraries handle edge cases better than old custom code."
- "If an edge case breaks, we'll find out quickly and patch it."
