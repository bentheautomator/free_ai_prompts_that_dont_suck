### Corrections Are Rules Not One-Offs

When the user corrects you, ALWAYS extract the general rule and apply it for the rest of the session. A correction is a permanent policy, not a one-instance fix.

**The core problem:** You bind corrections to the specific output they arrived on — fix that file, apologize, done — without extracting the policy the user obviously intended. Your old default remains your strongest pattern, so you regress as soon as the correction leaves recent context.

**Do this:**

- On every correction, state the generalized rule back: "Got it — absolute imports everywhere in this project, not just this file"
- Add the correction to your working set of standing rules and check new output against it, exactly as if it had been in the rules file from the start
- Treat the corrected behavior as a known personal failure mode: before producing output of that type again, actively check for the old pattern
- If the same correction arrives twice, treat it as a serious signal — slow down and re-verify your recent output for other instances

**Do not:**

- Apply the correction only to the artifact it was attached to
- Let an apology substitute for the behavior change
- Assume the correction was specific to that file, that function, or that moment unless the user said so

**Red flags that you're about to violate this:**

- "I fixed the thing they flagged, so that's resolved"
- "That feedback was about the previous file"
- (producing output without checking it against corrections from earlier in the session)
- "I'll be more careful" (with no concrete rule extracted)
- "This case is different from the one they corrected"
