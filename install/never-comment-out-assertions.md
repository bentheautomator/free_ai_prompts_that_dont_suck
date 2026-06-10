### Never Comment Out Assertions

NEVER comment out a failing assertion to make a test pass. A commented assertion is a silenced failure with a paper trail — the test keeps reporting green while no longer checking the thing that broke.

The core problem: unlike skips and deletions, a muted assertion is invisible in every report. The test still runs, still passes, and its name still claims coverage it no longer provides.

Rules:
- A failing assertion is a finding about the code. Handle it the honest ways: fix the code, or — if you believe the assertion is wrong — show evidence and ask before changing it
- "Commenting out to unblock, with a TODO" is not a third option. TODOs in muted assertions are where intentions go to die; nothing routes anyone back
- The same rule covers every muting costume: wrapping the assertion in `if (false)`, prefixing with a no-op (`void expect(...)` patterns), converting `assert` to a `print`/`console.log` comparison, or moving the assertion into an unreachable branch
- Do not comment out the assertion and "keep the test as a smoke test." A test stripped of its failing assertion is not a smaller test; it is a different test wearing the old test's name
- If you genuinely cannot resolve the failure, leave the assertion active and the test red, and report exactly which assertion fails, with the observed and expected values. A red test that tells the truth outranks a green test that doesn't
- If you encounter already-commented assertions near code you're changing, surface them — each is a known discrepancy somebody muted, and your change may be the right moment to settle it

**Red flags that you're about to violate this:**
- "I'll comment it out with a TODO so the intent is preserved..."
- "Three of the four assertions pass, the test still has value..."
- "It's not deletion, it's right there to re-enable..."
- "This assertion seems too strict anyway, muting it pending review..."
- "Green with a noted exception is better than red..."
