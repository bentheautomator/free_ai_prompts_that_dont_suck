---
title: Assert Specific Exceptions
slug: assert-specific-exceptions
category: testing
tags: [universal, testing, assertions]
works_with: all
severity: high
one_liner: "pytest.raises(Exception) passing on typos, crashes, and the wrong error alike"
---

# Assert Specific Exceptions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents error-path tests that pass when the code throws the wrong error for the wrong reason.

**[Copy-paste ready version](../../install/assert-specific-exceptions.md)** — just the instruction block, no explanation.

## The Problem

`with pytest.raises(Exception):` is the testing equivalent of asking "did anything go wrong?" and accepting any yes. Inside that block, a `TypeError` from a typo in the validation code, an `AttributeError` from a renamed field, and the `ValidationError` the test is nominally about are all indistinguishable — each one makes the test pass. The JavaScript twin is `expect(fn).toThrow()` with no argument, which is satisfied by `TypeError: Cannot read properties of undefined` just as happily as by the intended domain error.

AI assistants default to the broad form because it's robust to their own uncertainty: they're not always sure which exception class the code raises or what the message says, and `Exception` can't be wrong. That robustness is precisely the defect. An error-path test exists to pin down *which* failure occurs and *why*; the broad version converts "rejects invalid emails with a clear message" into "does not succeed," a bar so low that broken code clears it. Worse, when the validation logic itself crashes before reaching its raise statement, the broad matcher catches the crash and certifies it as correct rejection.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Assert Specific Exceptions

NEVER assert that code merely throws. Assert which exception type, and where it matters, what the message or error fields say. A bare `pytest.raises(Exception)` or `expect(fn).toThrow()` passes when the code crashes for an unrelated reason — including bugs in the error path itself.

The core problem: broad exception assertions can't distinguish "correctly rejected the input" from "fell over before reaching the rejection." Both look like a throw; only one is the behavior you meant to test.

Rules:
- Assert the concrete type: `pytest.raises(InvalidEmailError)`, `expect(fn).toThrow(ValidationError)`, `assertThrows(NotFoundException.class, ...)` — never the root `Exception`/`Error` class
- Pin the meaningful part of the message or payload when callers depend on it: `pytest.raises(ValidationError, match="email")`, `expect(fn).toThrow(/email/)`, or assert on the caught error's `code`/field attributes
- In JS, remember `toThrow()` on an async function needs `rejects`: `await expect(fn()).rejects.toThrow(ValidationError)` — the sync form on a promise tests nothing
- If you don't know what the code raises, that is not a reason to go broad — read the code path, then assert what you find (and check it's a sensible error; if invalid input raises `AttributeError`, you may have found a bug, not a fixture)
- Catch-and-inspect is fine when you need multiple assertions: catch the specific type, then assert on its fields. Don't catch broad and assert nothing
- Broad matching is acceptable only when the contract genuinely is "throws something" (rare, e.g., testing a panic handler) — say so when you use it

**Red flags that you're about to violate this:**
- "I'm not sure which exception it raises, Exception covers all cases..."
- "The important thing is that it fails on bad input..."
- "Matching the message makes the test brittle..."
- "toThrow() without arguments is cleaner..."
- "Any error here means the validation is working..."

---

## Why It Works

1. **It names the crash-equals-pass hole.** The AI doesn't model that a bug in the error path *also throws* and thereby passes the broad test. Making that failure concrete — typo throws TypeError, test goes green — turns "be specific" from style advice into a correctness requirement.

2. **It removes the uncertainty escape.** The AI goes broad because it doesn't know the exception type, and broad can't be wrong. Mandating "read the code path, then assert what you find" converts uncertainty into a research step instead of a license for vagueness.

3. **It addresses the brittleness objection in advance.** `match=` on a stable substring, or asserting an error code, pins the contract without coupling to full message text — neutralizing the rationalization the AI uses to avoid message assertions entirely.

## Origin

A team's input-validation suite asserted `pytest.raises(Exception)` across roughly sixty tests, courtesy of batch-generated coverage. A refactor introduced a `NameError` in the validator's first line, so every input — valid or not — raised. All sixty error-path tests passed; the happy-path tests in a different file caught nothing because they mocked the validator. Users couldn't submit any form for half a day, certified the whole time by a green suite that demanded only "throws something," which the broken code delivered abundantly.
