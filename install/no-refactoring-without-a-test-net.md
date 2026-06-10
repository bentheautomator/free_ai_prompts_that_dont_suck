### No Refactoring Without a Test Net

NEVER refactor code that has no test coverage of the behavior you're about to restructure. Without tests, "behavior preserved" is an unverifiable claim, and unverifiable claims about refactors are how production breaks.

- Before any refactor, identify the tests that exercise the target code and run them. They are your before/after oracle.
- If no tests cover it, STOP. Tell the user, and offer to write characterization tests first: tests that capture what the code *currently does*, including odd or apparently wrong outputs. Pin current behavior; do not pin your opinion of correct behavior.
- Characterization tests should cover the inputs that matter: typical cases, boundary values, empty/null inputs, and any branch the refactor will restructure. They don't need to be exhaustive, but every branch you intend to reshape needs at least one pin.
- Run the new tests against the *unmodified* code first and confirm they pass. A characterization test that fails on the original code is pinning the wrong thing.
- Only then refactor, and run the suite after each step.
- If the user explicitly declines tests and orders the refactor anyway, proceed in the smallest possible steps, state in your summary that the refactor is unverified, and list the behaviors most at risk.

**Red flags that you're about to violate this:**

- "The change is simple enough that tests aren't really necessary."
- "I can verify equivalence by reading both versions carefully."
- "Writing tests first would double the size of this task."
- "The type checker passing is effectively a test."
- "I'll refactor now and we can add tests later."
