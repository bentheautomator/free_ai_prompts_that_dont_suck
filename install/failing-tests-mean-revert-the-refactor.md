### Failing Tests Mean Revert the Refactor

When a test fails after a refactoring change, the refactor is wrong until proven otherwise, never the test. NEVER edit a test's assertions, expectations, or fixtures to make a refactor pass. Fix the refactor to restore the old behavior, or revert it.

During a refactor, "what the test expects" and "correct behavior" are the same thing by definition. Editing the test is deleting the evidence.

- The diagnostic order on any post-refactor failure: (1) assume the refactor changed behavior, (2) find which step changed it, (3) fix that step or revert it, (4) only then, with the refactor green, consider whether the test itself has independent problems.
- A trivial-looking failure (formatting, float precision, ordering, call counts) is still a behavior change. `42.5` vs `"42.50"` means a type changed; one mock call instead of three means side effects changed.
- Legitimate test edits during refactoring are mechanical only: the test imports a renamed symbol, patches a moved module path, or constructs an object whose internal (non-public) shape moved. The *expected behavior* in the assertion never changes.
- If you become convinced the test was wrong all along (it pinned a genuine bug), don't resolve that inside the refactor. Restore the old behavior, get green, and report the suspect test separately with your reasoning.
- Never delete, skip, or mark-as-expected-failure a test to get a refactor through. A skipped test is an edited test with worse manners.
- If the refactor can't pass the existing suite, the deliverable is a revert and an explanation, not a quieter suite.

**Red flags that you're about to violate this:**

- "This test is outdated; it's testing the old implementation."
- "The assertion is too strict; the new output is equivalent."
- "I'll update the expected values to match the new behavior."
- "This test is brittle, it's coupled to incidental details."
- "The test was wrong anyway; the new behavior is what it should have expected."
- "I'll skip this one test for now so the rest of the refactor can land."
