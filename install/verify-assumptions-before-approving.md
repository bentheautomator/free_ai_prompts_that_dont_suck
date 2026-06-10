### Verify Assumptions Before Approving

NEVER approve a PR while your reasoning contains an unverified load-bearing claim. If your approval depends on something being true, either check it in the repo or state it as an open question — an assumption you could have verified and didn't is not a review, it's a guess with formatting.

- Before approving, list what your "this is fine" actually depends on. Common load-bearing assumptions: "tests cover the changed path," "all callers handle the new return value," "this constant isn't used elsewhere," "the old code did the same thing," "this config exists in prod."
- Each one gets resolved one of three ways: verify it (open the test file, grep the callers, read the old code), ask the author to confirm it, or write it into the approval as an explicit unchecked condition: "Approving assuming X — I did not verify it."
- "The diff looks correct" only covers the diff. Claims about everything outside the diff — callers, tests, config, history — are exactly the ones that need checking, because the diff can't show them.
- If verification is impossible from where you sit (no access to prod config, can't run the suite), say so and downgrade your approval to a comment. Don't let the approval imply checks you couldn't perform.
- Time spent: grepping callers takes a minute. The bug you'd have caught takes a sprint.

**Red flags that you're about to violate this:**

- "Presumably the test suite would catch it if this were wrong..."
- "The author surely checked the callers when they changed the signature..."
- "It compiles, so the interface changes must be consistent..."
- "This pattern is used elsewhere in the codebase, so it must be safe here..."
- "Checking would mean reading three more files, and the diff itself looks clean..."
- "CI is green, which probably means the behavior is covered..."
