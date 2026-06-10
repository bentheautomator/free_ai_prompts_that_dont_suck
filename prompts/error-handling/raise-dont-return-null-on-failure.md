---
title: Raise, Don't Return Null on Failure
slug: raise-dont-return-null-on-failure
category: error-handling
tags: [universal, errors]
works_with: all
severity: high
one_liner: "AI returning None on failure, moving the crash far from its cause"
---

# Raise, Don't Return Null on Failure

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents failures from traveling through the program as null until they detonate somewhere unrelated.

**[Copy-paste ready version](../../install/raise-dont-return-null-on-failure.md)** — just the instruction block, no explanation.

## The Problem

Something goes wrong inside `parse_invoice()`, and instead of raising, it returns `None`. The None rides along: assigned to a variable, passed into `calculate_totals()`, stored on an object, until forty lines and two files later something calls `.line_items` on it and the program dies with `AttributeError: 'NoneType' object has no attribute 'line_items'`. The stack trace points at the totals code, which is innocent. The actual failure — a malformed date in the parser — left no trace at all, because returning None destroyed the error information at the moment it existed.

AI assistants love this move because `return None` reads as graceful. No scary raise statement, no exception to document, the function "degrades" instead of "crashing." But null is the one error signal that carries zero information — not what failed, not why, not even *that* something failed, since None is also a legitimate value in plenty of code. Every caller must now either check for None (most don't) or become the crash site.

The compounding version is worse: callers that receive None and themselves return None, building a null-propagation chain where the eventual crash is separated from its cause by half the codebase.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Raise, Don't Return Null on Failure

When an operation fails, raise an exception (or return an explicit error value in Result-style codebases). NEVER return `None`/`null`/`nil` as a stand-in for "something went wrong."

Null carries no information — not what failed, not why, not even that a failure occurred. It just relocates the crash to whichever distant line touches it first.

- `except Exception: return None` is forbidden; let the exception propagate, or wrap it with context and re-raise
- Returning null is legitimate only when null is a *meaningful answer to the question asked* — `find_user()` returning None for "no such user" is fine; `find_user()` returning None for "database unreachable" is a lie about what happened
- If a function can return null for absence, failures must still raise — never collapse "not found" and "couldn't look" into the same None
- Don't null-pad partial failures: if 3 of 10 fields failed to parse, raising beats returning an object with three silent Nones inside it
- In Go, return a non-nil `error` rather than a nil result with a nil error; in Rust/FP-style code, use the `Result`/`Option` types instead of sentinel nulls
- If you find yourself adding `if x is None: return None` to a caller, stop — you are extending a null-propagation chain; fix the producer to raise instead

**Red flags that you're about to violate this:**
- "Returning None is gentler than raising..."
- "The caller can check for None if they care..."
- "This way the function never throws..."
- "None is a natural way to say it didn't work..."
- "I'll pass the None along like the function below me does..."

---

## Why It Works

1. **It locates the real cost: distance.** The model evaluates `return None` at the function boundary, where it looks polite. Describing the deferred crash — wrong stack trace, innocent code blamed — shows the cost that only materializes downstream, outside the model's generation window.

2. **It preserves null's legitimate meaning.** Banning null entirely would conflict with idiomatic absence-returns and get ignored; the "meaningful answer to the question asked" test keeps `None` for "not found" while outlawing `None` for "lookup exploded."

3. **It calls out the propagation chain as a recognizable act.** `if x is None: return None` is the moment the antipattern reproduces; flagging that exact line interrupts the copy.

4. **It distinguishes raising from rudeness.** Models treat exceptions as failures of craftsmanship. Framing the raise as *information delivery* — what failed, why, where — recasts it as the careful option.

## Origin

A scheduling system's AI-written availability checker returned None whenever the calendar API errored. The None flowed into a comparison, where Python 2-era code coerced it in a way that evaluated as "available." Double-bookings started appearing at a rate of a few per day — only when the API hiccuped, only for certain request timings — and were chased as a race condition for two weeks. The fix was one line: raise on API failure instead of returning None. The bug had never been anywhere near the booking logic everyone was staring at.
