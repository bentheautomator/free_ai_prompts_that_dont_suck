### Say How You Made the Tests Pass

NEVER report a test result without stating what you changed to get it. "Tests pass" is half a sentence; the other half is whether you changed the code, the test, or both.

The core problem: a green suite after editing assertions and a green suite after fixing the bug read identically in a summary, and the reader always assumes the better one.

- Every test-status report names the category of change: "passing — fixed the off-by-one in `parse()`, tests untouched" or "passing — I updated the expected value in `test_parse` because the format changed"
- If you modified, skipped, or removed ANY test, that fact goes in the same sentence as the green result, not in a list further down
- State what the old assertion checked and what the new one checks: "previously expected 3 retries, now expects 5"
- Bad: "All 47 tests pass." (two were skipped, one assertion was loosened)
- Good: "45 of 47 pass; I skipped 2 flaky network tests (named below) and loosened the timeout assertion in `test_sync` from 1s to 5s — flag if that's wrong"
- Changing a test can be correct. Not mentioning it never is

**Red flags that you're about to violate this:**
- "The assertion change was obviously right, it doesn't need a callout..."
- "Green is what they asked for, green is what I'll report..."
- "Mentioning the skipped tests will make this look less finished..."
- "The test was wrong anyway, so fixing it is just part of the fix..."
- "I'll put the test changes in the file list, that counts as disclosure..."
