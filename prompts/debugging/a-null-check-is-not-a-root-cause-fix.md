---
title: A Null Check Is Not a Root Cause Fix
slug: a-null-check-is-not-a-root-cause-fix
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI guarding the crash site when the real bug is why the value is null"
---

# A Null Check Is Not a Root Cause Fix

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from answering "why is this null?" with "what if we just checked for null?"

**[Copy-paste ready version](../../install/a-null-check-is-not-a-root-cause-fix.md)** — just the instruction block, no explanation.

## The Problem

`Cannot read properties of undefined`. `NoneType has no attribute`. `NullPointerException`. The AI's reflex is identical every time: wrap the crash site in a guard. `user?.profile?.email ?? ""`. `if obj is not None:`. The crash stops. But the interesting question — why was a value that the code's whole design assumes exists suddenly *absent*? — was never asked. A user record with no profile didn't stop existing because you optional-chained past it; it proceeded through the system as an empty string.

The null guard is the purest form of symptom patching because the error message literally names the symptom ("it was null") and the guard literally addresses only that sentence. Assistants reach for it because it's a one-line edit at the exact location in the trace, requiring zero understanding of the data flow that produced the null. Tracing that flow means reading callers, queries, and initialization order — real work.

The compounding cost: each guard converts a loud crash into quiet wrongness. Empty emails get sent. `undefined` gets stringified into URLs. Sums silently skip rows. A codebase managed this way fills up with `?.` until nothing crashes and nothing can be trusted.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### A Null Check Is Not a Root Cause Fix

NEVER fix a null/undefined/None crash by only adding a guard at the crash site. First answer the actual question: why was this value absent when the code expected it to exist?

The error names the symptom, not the bug. The bug is upstream, wherever the absence was created or allowed through.

- Trace the null to its origin: where was this value supposed to be set, and what path skipped that? (failed lookup, missing await, optional field, bad join, init order, error swallowed earlier)
- Decide which case you're in: (a) the value should always exist — fix the upstream code or data that failed to provide it; (b) absence is a legitimate state — handle it *meaningfully* (skip, default, error message) with behavior someone chose on purpose, at the right layer
- A guard that substitutes an empty/default value must be justified: state what the program now does with that default and why that's correct, not just non-crashing
- Never resolve it with a bare optional chain or `if x:` whose else-branch is "silently continue" — that converts a crash into undetectable wrong behavior
- If you add a guard as a stopgap, say so explicitly and report the unanswered upstream question; do not present the guard as the fix

**Red flags that you're about to violate this:**
- "Simple fix — just need a null check here..."
- "Optional chaining handles this case cleanly..."
- "Defaulting to an empty array makes this safe..."
- "Whatever's making it null, the code should be defensive anyway..."
- "The why doesn't matter as long as we don't crash..."
- Fixing the crash without being able to say where the null came from

---

## Why It Works

1. **It separates the symptom sentence from the bug.** The error message's own wording ("was null") steers the AI toward guarding; explicitly stating that the message names the symptom redirects attention upstream where the bug lives.

2. **It forces the existence question.** "Should this value always exist?" has two answers with two different correct fixes. The guard reflex answers neither; the instruction makes choosing one mandatory.

3. **It exposes the crash-to-silence trade.** A crash is detectable; a defaulted empty value is not. Naming that conversion makes "at least it doesn't crash" read as the downgrade it usually is.

4. **It permits honest stopgaps.** Sometimes a guard *is* the right immediate move — but only labeled as one, with the open question reported, so the root cause doesn't get closed by accident.

## Origin

A dashboard crashed nightly on `metrics.revenue` being undefined. The assistant shipped `metrics?.revenue ?? 0` and the crash disappeared. So did a fifth of the company's reported revenue, for three weeks, because the actual bug was a pagination change that dropped the last page of the metrics query. The crash had been the only alarm. The guard turned off the alarm and left the fire.
