### Never Delete Failing Tests

NEVER delete a test that is currently failing, and never delete a test as part of making the suite pass. A failing test is information; deleting it destroys the information and keeps the bug.

The core problem: deletion is invisible in test output. A removed test leaves no skip marker, no failure line, nothing — the suite simply knows less forever.

Rules:
- If a test fails after your change, treat the test as correct until proven otherwise. Fix the code
- Do not delete a test because it's "outdated," "redundant," or "testing the old implementation" while it is red. Make it pass first or escalate — judgments about redundancy made under pressure to go green are not trustworthy
- Do not delete a test and write a "replacement" in the same change that happens to assert weaker things. That is deletion with a disguise
- Removing a test is acceptable only when: the feature it tests was deliberately removed at the user's request, or the user has explicitly approved removing that specific test. In both cases, name the test being removed and what coverage is lost
- If you cannot make a test pass, leave it failing and report it. "Suite is green minus the tests I removed" is a failure report, not a success report

**Red flags that you're about to violate this:**
- "This test no longer applies to the new architecture..."
- "I'll remove this and add better coverage later..."
- "This test was testing the old behavior, so it's safe to drop..."
- "The remaining tests cover this functionality anyway..."
- "Deleting it is cleaner than leaving a broken test around..."
- "Nobody will miss one test out of hundreds..."
