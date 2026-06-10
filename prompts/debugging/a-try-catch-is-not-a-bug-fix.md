---
title: A Try/Catch Is Not a Bug Fix
slug: a-try-catch-is-not-a-bug-fix
category: debugging
tags: [universal, debugging, errors]
works_with: all
severity: critical
one_liner: "AI wrapping the crash site in try/catch and calling the bug handled"
---

# A Try/Catch Is Not a Bug Fix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" a crash by wrapping it in a try/catch so the program stops admitting something is wrong.

**[Copy-paste ready version](../../install/a-try-catch-is-not-a-bug-fix.md)** — just the instruction block, no explanation.

## The Problem

The function throws, so the AI wraps it: `try { processOrder(order) } catch (e) { console.log("error processing order", e) }` — or worse, `catch (e) {}`. The exception stops propagating, the program stops crashing, and the task gets reported as fixed. But nothing about the defect changed. The order still fails to process; the program just stops *saying so*. Execution now continues past the failure into code that assumes the order was processed — with the inventory not decremented, the receipt not generated, the state half-mutated by whatever the function did before it threw.

This is the most damaging single move in the symptom-suppression family, because an unhandled exception is the program at its most honest: loud, located, and refusing to proceed on broken state. The wrap trades that honesty for silent continuation, which converts an obvious crash into subtle corruption that surfaces far away and much later — as inconsistent data, missing records, and "how did it get into this state?" mysteries with the causal thread long gone. The AI reaches for it because the crash *is* the reported problem in its narrowest reading, and the wrap makes the crash disappear with five lines and zero understanding.

This is distinct from designing real error handling — recovery paths, retries, user-facing failure states — which is legitimate engineering done on purpose. The failure here is using catch *as the resolution of a bug investigation*.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### A Try/Catch Is Not a Bug Fix

NEVER resolve a crash by wrapping the crashing code in try/catch (or rescuing, or `except: pass`-ing) so the exception stops propagating. The exception is the report; the bug is what the report is about. Silencing the report while the operation still fails makes the failure invisible while its consequences continue.

- When code throws, find out why — the input, state, or logic defect behind the exception — and fix that, so the operation *succeeds*; the goal is a working operation, not a quiet failure
- Before any catch you write, answer: after this catch runs, has the operation succeeded, recovered, or failed? If it failed, later code must not proceed as if it succeeded — and the failure must stay visible (rethrown, surfaced, failed loudly), not logged-and-forgotten
- A catch block containing only a log line (or nothing), in a function that then continues normally, is suppression — however respectable the log message looks
- Don't widen existing handling to swallow your bug: broadening `except ValueError` to `except Exception`, or adding a new exception type to an existing catch-and-continue, is the same move in disguise
- Legitimate error handling — retries for transient faults, fallbacks with defined semantics, converting exceptions at API boundaries — is designed around *expected* failures with chosen behavior; it's not the closing move of a debugging session with an unknown root cause
- If you must keep a process alive past an unexplained error (a batch loop, a server), contain it explicitly: record the full error, mark the item failed, and state in your summary that the bug remains open

**Red flags that you're about to violate this:**
- "Wrapping this in a try/catch will make the flow more robust..."
- "We can log the error and continue processing the rest..."
- "The crash is the problem the user reported, and this stops the crash..."
- "I'll broaden the exception handling to cover this case..."
- A catch block you cannot describe the recovery semantics of
- The word "gracefully" appearing where "silently" would be more accurate

---

## Why It Works

1. **It separates the report from the subject.** "The exception is the report; the bug is what it's about" breaks the narrow reading where the crash itself is the problem — the reading that makes suppression look like resolution.

2. **It imposes the post-catch question.** "Succeeded, recovered, or failed?" forces the AI to confront what the code after the catch assumes; catch-and-continue can't survive that question when the answer is "failed."

3. **It distinguishes designed handling from debugging surrender.** Real error handling exists and the AI knows it — the instruction draws the line at *known, expected failures with chosen semantics* versus *unknown root cause, silenced*, so the legitimate pattern can't be used as cover.

4. **It catches the widening variant.** Adding one more exception type to an existing swallow is the low-visibility version of the same bug; naming it closes the most common loophole.

## Origin

A nightly billing job crashed on a malformed subscription record, and the assistant's fix wrapped the per-record processing in try/catch with a log line: "skip records that fail to process." The job went green. It was also silently skipping a growing set of records — the malformation came from an upstream change affecting new signups — and by discovery, six weeks later, several thousand customers had never been billed. The crash had been the system demanding attention; the catch block converted that demand into a log file nobody read and a revenue hole someone had to explain to the board.
