---
title: Rerun the Original Repro After the Fix
slug: rerun-the-original-repro-after-the-fix
category: verification
tags: [universal, verification, bugfix]
works_with: all
severity: high
one_liner: "Claiming a bug is fixed without rerunning the case that demonstrated the bug"
---

# Rerun the Original Repro After the Fix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from declaring a bug fixed without rerunning the exact failing case that defined the bug.

**[Copy-paste ready version](../../install/rerun-the-original-repro-after-the-fix.md)** — just the instruction block, no explanation.

## The Problem

A bug report comes with a definition of done built in: the steps that fail. Run these steps, see this wrong behavior. An assistant reads the report, forms a theory, edits the code, and declares "fixed" — having never run the failing steps once, before or after. The fix is verified against the theory, not against the bug. If the theory was wrong (the report describes a symptom, the assistant fixed a different cause), the edit is a confident no-op and the user discovers the bug again, now with less patience.

This shortcut is tempting because reproductions are work: setting up the failing input, the specific account state, the sequence of clicks. The theory, by contrast, is already in hand, and the code change visibly addresses it. "I fixed the cause of the bug" feels equivalent to "I fixed the bug" — but the first is a claim about the assistant's model of the problem, and the second is a claim about the world. Sometimes the assistant even runs *something* — a fresh happy-path check, a related test — and lets that stand in for the one execution that actually defines success.

The repro is the bug's own acceptance test, handed over for free. Skipping it means shipping a fix whose central property — does the failing thing now work? — was never observed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rerun the Original Repro After the Fix

NEVER claim a bug is fixed until the original reproduction — the exact input, steps, or command that demonstrated the bug — has been rerun against your fix and now behaves correctly.

The core problem: a fix is verified against your theory of the bug unless the failing case itself is rerun. "I addressed the cause" is a claim about your diagnosis; "the repro now passes" is a claim about reality. Only the second one is "fixed."

- Reproduce first when feasible: run the failing case before changing anything and watch it fail the way the report says. A fix for a failure you never saw is aimed at a description, not a behavior.
- After the fix, rerun the same case — same input, same steps, same environment particulars the report named. Not a similar case, not the happy path next door: the one that failed.
- Observe correct behavior, not just different behavior. The original error disappearing into a new error, a blank result, or a silent no-op is a changed bug, not a fixed one.
- If you cannot execute the repro (requires production data, specific hardware, a user's account state), build the closest executable proxy, run that, and label the result: "proxy repro passes; original conditions unverified."
- Report the before/after pair: "repro previously produced X; after the fix it produces Y, which is correct." That sentence requires both runs to have happened.
- Intermittent bugs need repetition, not one lucky pass: state how many reruns you did and the hit rate before and after.

**Red flags that you're about to violate this:**
- "The code change clearly addresses what the report describes..."
- "Setting up the repro takes longer than the fix did..."
- "I ran the feature normally and it works, so the bug is gone..."
- "The root cause is obvious; reproducing it first is ceremony..."
- "A related test passes now, which covers it..."
- "It didn't throw the old error, so we're done..."

---

## Why It Works

1. **It separates diagnosis from outcome.** "I fixed the cause" and "the bug is fixed" feel synonymous and aren't — the rule names the gap, which is exactly where wrong theories hide.

2. **It treats the repro as the acceptance test it is.** Reframing the failing steps as the bug's built-in definition of done makes skipping them feel like skipping the test, not skipping a chore.

3. **It blocks substitute evidence.** Happy-path runs and adjacent tests are the standard stand-ins; explicitly disqualifying "a similar case" closes the loophole that lets some execution impersonate the right execution.

4. **It requires different to also be correct.** Demanding observed-correct behavior (not just the old error's absence) catches fixes that merely relocate the failure.

## Origin

A report said exports failed for files over 100MB with a timeout. The assistant found a plausible-looking timeout constant, tripled it, and reported the bug fixed — without ever exporting a large file. The actual failure was a memory limit that killed the worker at around the same elapsed time; the timeout was a bystander. The user retried a 200MB export the next day, hit the identical failure, and the report reopened with the subject line "still broken, was this tested?" It had been fixed twice before anyone ran the repro once.
