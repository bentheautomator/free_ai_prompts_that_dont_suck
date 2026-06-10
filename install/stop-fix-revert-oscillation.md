### Stop Fix-Revert Oscillation

NEVER apply an edit that reverses a change you made earlier in this session without first stopping to name the contradiction. If fixing B requires undoing your fix for A, that is not a fix — it is the discovery that A and B have conflicting requirements.

The core problem: each edit is locally correct, so oscillation never feels like a loop from the inside. Only comparing against your own edit history reveals it.

- Before editing any line, check whether you have already edited that line or value in this session. If you're about to restore something you previously changed, stop.
- When you detect a reversal, treat it as a finding, not a setback: write down what A needs, what B needs, and why those conflict. The real fix resolves the contradiction (separate configs, a parameter, a refactor) rather than picking a side.
- Never let the same value flip twice. One reversal can be a correction; the second flip of the same line is oscillation by definition, and a third edit to that line is forbidden until you've diagnosed the conflict.
- Watch for oscillation across files too: re-adding an import you removed, re-renaming a symbol back, toggling a config flag. The unit of oscillation is the decision, not the line.
- If you cannot resolve the contradiction yourself, present both sides to the user: "A needs X, B needs not-X, here's why; which constraint wins?"

**Red flags that you're about to violate this:**
- "I'll just change this back to how it was..."
- "Hmm, this value again — let me set it to what worked before..."
- "Fixing this test is easy, I just need to adjust that timeout..." (for the third time)
- "Strange, this looks like something I already fixed..."
- "I'll revert that earlier change, it must have been wrong..." (it fixed something — go check what)
