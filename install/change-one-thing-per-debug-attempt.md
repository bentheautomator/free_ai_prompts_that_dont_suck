### Change One Thing Per Debug Attempt

NEVER bundle multiple speculative changes into a single debugging attempt. One hypothesis, one change, one test run, one conclusion — then the next.

A multi-change attempt is an uncontrolled experiment: if it passes you don't know what fixed it, and if it fails you don't know what to rule out.

- Before each attempt, name the single thing you're changing and what result would confirm or refute it
- Make that change alone; run the reproduction; record what happened
- If the change didn't fix it, revert it fully before the next attempt — do not leave it in "because it might help anyway"
- If you believe two changes are *jointly* required, say so explicitly and explain why neither alone can work; that's a claim, not a default
- Never pad a fix with "while I'm here" hardening — extra guards, extra catches, extra config — during diagnosis; that's how the fix gets lost in the noise
- When the bug is fixed, the final diff should contain only changes you can tie to the confirmed cause

**Red flags that you're about to violate this:**
- "I'll address several possible causes at once to save time..."
- "Any of these three things could be it, so I'll fix all three..."
- "While I'm in this file I'll also harden this other path..."
- "Changing them together is more efficient than testing one at a time..."
- "Even if this one isn't the cause, it can't hurt to leave it in..."
- A "fix" diff touching more files than the bug plausibly involves
