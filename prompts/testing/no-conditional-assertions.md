---
title: No Conditional Assertions
slug: no-conditional-assertions
category: testing
tags: [universal, testing, assertions]
works_with: all
severity: high
one_liner: "Tests where assertions hide behind if-statements and silently never run"
---

# No Conditional Assertions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests whose assertions only execute when conditions happen to allow it, passing vacuously otherwise.

**[Copy-paste ready version](../../install/no-conditional-assertions.md)** — just the instruction block, no explanation.

## The Problem

This test passes whether the feature works or not:

```javascript
const user = await findUser('alice');
if (user) {
  expect(user.role).toBe('admin');
}
```

If `findUser` is broken and returns `null`, the `if` is skipped, zero assertions run, and the test runner — which treats "no assertion failed" as success — prints green. The AI wrote the guard to avoid a `TypeError: cannot read 'role' of null`, which felt like defensive programming. But in a test, that null *was the failure*, and the guard converted it into a pass. The same shape appears as `if (response.ok) { ...asserts... }`, `if len(results) > 0:` before checking contents, or asserting only inside an `else` branch that wrong code never reaches.

AI assistants generate this constantly because production habits transfer: guard before dereference is correct almost everywhere except inside a test, where unconditional assertions are the entire point. The result is a suite where some unknown fraction of tests are conditional no-ops, indistinguishable from real ones in the output.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Conditional Assertions

NEVER put a test's assertions inside an `if` (or any condition) that can skip them. A test where the assertions might not run is a test that might be testing nothing — and the runner will still report it as passing.

The core problem: test runners count failures, not assertions. When the guard condition is false, no assertion executes, and silence is scored as success — precisely when the code is most broken.

Rules:
- Assert the condition itself, unconditionally, then proceed: `expect(user).not.toBeNull()` followed by `expect(user.role).toBe('admin')`. The null case must FAIL, not skip
- Never write `if (result) { expect(...) }`, `if response.ok: assert ...`, or assertions reachable only via one branch of the data's behavior. If the data determines which branch runs, the wrong branch must hit a failing assertion or an explicit `fail()`/`pytest.fail()`
- For legitimately environment-dependent tests (feature flag off, platform-specific), use the framework's explicit skip with a reason (`test.skipIf`, `@pytest.mark.skipif`) so the report shows SKIPPED — never an `if` that lets the test pass silently
- Guarding against exceptions with conditionals is solving the wrong problem: in a test, the crash was a correct failure signal. Don't trade a loud crash for a quiet pass
- Audit check: count assertions that are guaranteed to execute on every path. If the answer can be zero, the test is broken regardless of its color

**Red flags that you're about to violate this:**
- "I'll guard the dereference so the test doesn't crash on null..."
- "Only check the body if the response succeeded..."
- "This avoids a TypeError when the list is empty..."
- "If the data isn't there, there's nothing to assert anyway..."
- "Defensive coding makes the test more robust..."

---

## Why It Works

1. **It exposes the runner's accounting.** The AI assumes the runner verifies that testing happened; it only verifies that no assertion failed. Making "silence scores as success" explicit shows why the guard is a hole, not a courtesy.

2. **It inverts the defensive instinct.** "Guard before dereference" is correct production code and wrong test code. Naming the transfer error — the null was the failure — lets the AI keep the instinct where it belongs.

3. **It channels real conditionality into visible skips.** Some tests legitimately don't apply everywhere. Routing those through framework skips (which show in reports) removes the only honest use case for the silent-pass pattern.

## Origin

A search feature regressed to returning empty results for every query containing a hyphen. The test for hyphenated queries had passed throughout: it fetched results, then asserted relevance ordering inside `if (results.length > 0)`. The guard had been added by an assistant to stop the test "crashing on empty result sets" — which was the regression, reporting itself, being politely shown out. The bug ran in production for a month with its dedicated test green the entire time.
