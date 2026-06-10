---
title: Corrections Are Rules Not One-Offs
slug: corrections-are-rules-not-one-offs
category: instruction-following
tags: [universal, rules, memory]
works_with: all
severity: high
one_liner: "AI fixes what you corrected, then regresses two responses later"
---

# Corrections Are Rules Not One-Offs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the correct-comply-regress loop where the AI fixes the behavior you flagged and then reverts to it within a few responses.

**[Copy-paste ready version](../../install/corrections-are-rules-not-one-offs.md)** — just the instruction block, no explanation.

## The Problem

You tell the AI: "Stop using relative imports — this project uses absolute imports." It apologizes, fixes the file, and uses absolute imports in its very next edit. Two responses later: relative imports again. You correct it again. It complies again. The loop can run all session, with the AI sincerely apologizing each time, because the correction was processed as "fix this instance" rather than "this is now a rule."

The mechanism is scope assignment. A correction arrives attached to a specific piece of output, so the AI binds it to that output: file fixed, correction satisfied, done. The general policy the user obviously intended — *never do this again* — was never extracted. Meanwhile the underlying default that produced the mistake is still the strongest pattern available, so as soon as the correction scrolls out of recent context, the default wins again.

For the user this is uniquely exhausting: every correction has to be re-issued indefinitely, and each regression after an apology reads as either incompetence or indifference.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It forces the generalization step.** Regression happens because the policy was never extracted, only the instance fixed. Requiring the rule to be stated back ("absolute imports everywhere") makes the generalization an explicit artifact instead of a hoped-for inference.

2. **It promotes corrections to rules-file status.** Treating mid-session corrections as equal members of the standing rule set means they get whatever rule-checking machinery the AI applies, rather than living as fading conversational residue.

3. **It targets the regression moment.** The old default wins when output of the same type is produced without a check. "Before producing that type of output again, look for the old pattern" inserts the check exactly where the relapse occurs.

4. **It makes repeat corrections an alarm.** A second identical correction means the loop is active. Escalating it to "slow down and audit" breaks the apologize-regress cycle instead of running another lap of it.

## Origin

A developer corrected their assistant early in a session: error responses must use the project's error envelope, never bare strings. The AI fixed the endpoint, confirmed the convention, and over the next three hours shipped bare-string errors in four more endpoints — each one corrected, each one apologized for. The developer ended the session auditing every endpoint the AI had touched, having spent more time re-issuing one instruction than the feature took to build.
