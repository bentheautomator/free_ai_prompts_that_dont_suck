---
title: Change One Thing Per Debug Attempt
slug: change-one-thing-per-debug-attempt
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI changing five things at once and learning nothing from the result"
---

# Change One Thing Per Debug Attempt

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents shotgun debugging — bundling five speculative changes into one attempt so the result teaches you nothing.

**[Copy-paste ready version](../../install/change-one-thing-per-debug-attempt.md)** — just the instruction block, no explanation.

## The Problem

Faced with a stubborn bug, an AI assistant will often produce a diff that touches five files: tweak the config, add a guard, reorder two calls, bump a dependency, and adjust a query. One of these might be the fix. The other four are noise. When the test passes, nobody — including the AI — knows which change mattered, and the codebase has absorbed four unjustified edits that someone will be afraid to remove for years.

When the shotgun blast *doesn't* work, it's even worse: you've learned nothing, because every hypothesis was tested simultaneously and the failure doesn't tell you which ones to discard. Real debugging is an experiment loop — change one variable, observe, conclude. Five variables per run is zero experiments, run five times faster.

Assistants shotgun because each speculative change is individually cheap to generate, and bundling them feels thorough — "I addressed several potential causes." It reads like diligence. It is the opposite: a refusal to find out which cause is real.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It restores the experiment structure.** Debugging only produces knowledge when one variable changes per run. The instruction makes the AI's loop match the scientific loop instead of a buckshot pattern.

2. **It reframes bundling as anti-diligence.** The model treats "addressed multiple causes" as thoroughness. Naming it as a refusal to identify the real cause removes the virtuous gloss.

3. **It keeps the final diff explainable.** Requiring every surviving line to trace to the confirmed cause prevents the four dead speculative edits from shipping as superstition.

4. **It closes the "can't hurt" loophole.** Unjustified leftover changes are exactly how codebases accrete mystery guards; the explicit revert rule makes leaving them in a violation, not a kindness.

## Origin

An assistant was asked to fix an intermittent 502 from an internal API. Its first attempt changed the connection pool size, added a retry wrapper, bumped the HTTP client library, and lowered a keepalive timeout — in one commit. The 502s stopped. Four months later the retry wrapper was found to be re-sending non-idempotent payment requests, and nobody could say whether it was even the change that had fixed anything. Unwinding it required re-debugging the original bug from scratch, this time one change at a time, which took an afternoon and ended in a one-line keepalive fix.
