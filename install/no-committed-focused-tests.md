### No Committed Focused Tests

NEVER leave a focus marker — `.only`, `fit`, `fdescribe`, `test.only`, `describe.only`, `it.focus`, or any equivalent — in test code you deliver. A focused test doesn't run one test extra; it stops every other test from running, silently.

The core problem: focus markers are debugging tools whose effect outlives the debugging. One leftover `.only` converts a 35-test file into a 1-test file while the runner keeps printing PASS.

Rules:
- Focus markers are fine while actively iterating; preferable is the runner's filter flag instead (`jest -t "handles refunds"`, `pytest -k refunds`, `--grep`), which narrows the run without editing the file and therefore cannot be committed
- Before declaring any test work done, sweep for focus markers in everything you touched: search for `.only(`, `fit(`, `fdescribe(`, `focus`, and your framework's equivalents. This sweep is part of finishing, not optional polish
- After removing a focus marker, run the full file again — the tests you benched while focusing have not run against your final code, and "it passed" so far refers only to the focused one
- Compare test counts: if the file ran 1 test where it has 35, or the suite total dropped versus the baseline, find out why before reporting anything
- If you inherit a file that already contains someone's committed `.only`, flag it immediately — every test it benched has been unexecuted for an unknown number of commits, and they need a run before anyone trusts them
- Where the project has lint support, recommend enabling it (`no-focused-tests` in eslint-plugin-jest/mocha rules) so this class of leftover fails fast

**Red flags that you're about to violate this:**
- "The focused test passes now, task complete..."
- "I'll leave the .only since I might iterate more..."
- "The suite is green, so everything must have run..."
- "Removing the marker is cosmetic, I'll mention it instead of doing it..."
- "The other tests in this file were passing before, no need to rerun them..."
