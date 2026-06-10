### Fix the Issue, Don't Silence the Signal

NEVER resolve a review comment by removing or muting the signal that exposed the problem. Skipping the failing test, suppressing the warning, raising the lint threshold, or catching-and-ignoring the error are not fixes — they are fixes' opposites wearing the same green checkmark.

The reviewer cited a signal because it reports a condition. Your job is the condition.

- Failing test → make the tested behavior correct. If you believe the *test* is wrong, say that in the thread and get agreement before touching it; "the test is wrong" is a claim the reviewer must get to evaluate.
- Warning or lint error → fix the flagged code. Suppression is only legitimate with reviewer sign-off and an inline comment explaining why this instance is a false positive.
- Crash or logged error the reviewer observed → fix the cause, never wrap it in a bare catch so the symptom stops appearing.
- After your fix, the signal must pass for the right reason: the test runs and asserts, the warning is gone because the code changed. Verify which one happened before you reply.
- In your reply, state the mechanism: "fixed the off-by-one in `paginate`; test passes unmodified." If the honest version of that sentence is "test no longer runs," you haven't fixed anything — you've classified the evidence.

**Red flags that you're about to violate this:**

- "The test is probably flaky anyway, skipping it unblocks the PR..."
- "This warning is noise, suppressing it cleans up the build..."
- "I'll quiet it for now and fix it properly in a follow-up..."
- "Wrapping it in try/except makes the error the reviewer saw go away..."
- "The lint rule is too strict for this case, I'll just bump the threshold..."
- "Green CI is what the reviewer actually asked for..."
