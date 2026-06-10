---
title: No Unrequested Error Handling
slug: no-unrequested-error-handling
category: scope
tags: [universal, scope, over-engineering]
works_with: all
severity: high
one_liner: "AI wrapping everything in try/catch and null guards nobody asked for"
---

# No Unrequested Error Handling

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from blanketing code in try/catch blocks, null checks, and fallback values that were never requested.

**[Copy-paste ready version](../../install/no-unrequested-error-handling.md)** — just the instruction block, no explanation.

## The Problem

Ask for a function that reads a config file and you get a function that reads a config file inside a try/except that catches `Exception`, logs a warning, and returns `{}`. Ask for a change to a data pipeline step and every dict access in the function now goes through `.get()` with a default, every argument gets an `if not x: return None` guard, and three layers of the call stack independently handle the same hypothetical failure. None of this was requested. All of it changes behavior.

Assistants drench code in error handling because it pattern-matches to "robust" and "production-ready." But unrequested error handling is unrequested behavior change of the most dangerous kind: it converts loud failures into quiet wrong answers. The config function that returns `{}` on a parse error doesn't crash — it runs the whole system on empty config and fails somewhere far away, later, mysteriously. The original code would have thrown at the actual problem with a stack trace pointing at it.

Error handling is design, not garnish. What's recoverable, what should propagate, what the fallback semantics are — those are decisions the request either specifies or the user needs to make. Defaulting to "catch everything, return something" makes the decision silently, and usually wrong.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Unrequested Error Handling

Add error handling only where the request asks for it or where the operation's failure genuinely cannot propagate. NEVER wrap code in catch-all handlers, null guards, or silent fallbacks on your own initiative.

The core problem: swallowing an error replaces a loud failure at the cause with a quiet wrong answer far from it, and that semantic change was never requested.

- Let exceptions propagate by default; a crash with a stack trace at the real problem is correct behavior, not a defect to suppress
- Do not catch broad exception types and log-and-continue, return None, or return an empty collection unless those exact semantics were specified
- Do not add null/undefined guards for values the surrounding code already guarantees; do not guard the same condition at multiple layers
- Do not invent fallback values; choosing what a failure "means" is a product decision, not a formality
- Preserve existing error behavior in code you edit; do not narrow, widen, or add handlers in passing
- If you believe a specific failure mode genuinely needs handling, name it and the proposed semantics in one sentence ("this can throw on X; want it to Y?") and let the user decide

**Red flags that you're about to violate this:**
- "I'll add a try/except to make this more robust..."
- "Better to return an empty list than crash..."
- "Defensive programming, just in case this is None..."
- "Production code should handle every failure gracefully..."
- "I'll log the error and continue so one bad record doesn't stop the batch..."
- "Wrapping this can't hurt..."

---

## Why It Works

1. **It redefines "robust."** The AI equates robustness with not crashing; stating that a stack trace at the cause beats a wrong answer downstream flips the value of the crash.

2. **It classifies error handling as behavior, not boilerplate.** Once handlers count as semantic changes, the existing "only the requested change" discipline applies to them automatically.

3. **It forces the fallback decision into the open.** "Return `{}` on failure" is a product decision the AI was making silently; the ask-first clause converts it into a question with named semantics.

4. **It blocks layered double-handling.** The multi-layer guard clause is creep that survives even when single guards are policed; banning duplicate handling by name closes that gap.

## Origin

A pipeline maintainer asked an assistant to add one field to a record transformation. The delivered function also gained a try/except around the parse step that logged and skipped bad records, where previously a bad record halted the run. A malformed upstream export then silently dropped 14% of a week's records; the dashboards just showed lower numbers. Reconstructing the lost data took longer than the original feature, and the lost week was the one the quarterly report drew from.
