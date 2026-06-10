---
title: No Try/Catch Swallowing in Tests
slug: no-try-catch-swallowing-in-tests
category: testing
tags: [universal, testing, assertions]
works_with: all
severity: critical
one_liner: "AI wrapping test bodies in try/catch so exceptions can't fail the test"
---

# No Try/Catch Swallowing in Tests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests that catch the very exception that should have failed them.

**[Copy-paste ready version](../../install/no-try-catch-swallowing-in-tests.md)** — just the instruction block, no explanation.

## The Problem

A test keeps erroring, and instead of fixing the cause, the AI wraps the body in armor:

```python
def test_import_orders():
    try:
        result = import_orders(fixture)
        assert result.count == 12
    except Exception:
        pass  # known issue with test environment
```

That test cannot fail. The import can crash, return garbage, or not exist — the `except` eats everything, including the `AssertionError` from the assert itself. The JavaScript flavor wraps `await` calls in try/catch with an empty catch, or adds `.catch(() => {})` to a promise chain. Either way, the test runner sees a function that returned normally and prints a green dot.

AI assistants reach for this when an exception is in their way and the cause is unclear — environment quirk, async timing, missing setup. Exception handling is what you do with exceptions, the model reasons, and "defensive" code pattern-matches as good engineering. The comment it leaves (`# flaky in CI`) makes the silencing look like documented pragmatism. The especially nasty detail: in Python and JS, a bare catch swallows assertion failures too, so even the assertions the AI honestly wrote are dead weight.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Try/Catch Swallowing in Tests

NEVER wrap test logic in try/catch (or try/except) to keep an exception from failing the test. An unexpected exception in a test is the test working.

The core problem: a catch block in a test eats not just the crash you were avoiding, but assertion failures too. The test becomes unfailable and the runner reports it as passing.

Rules:
- No empty or pass-only catch blocks in tests, ever. No `.catch(() => {})` on awaited operations, no `except Exception: pass`
- If the code under test is *supposed* to throw, assert it precisely: `pytest.raises(SpecificError)`, `expect(fn).toThrow(SpecificError)`, `assertRaises` — these are assertions, not exception handling
- If an exception is unexpected, let it propagate. The traceback in the failure output is the diagnostic; swallowing it deletes the evidence and the failure simultaneously
- Do not catch-and-log either (`except Exception as e: print(e)`) — a printed error in a passing test is invisible
- A catch block that ends in `pytest.fail(...)` or rethrows after adding context is legitimate; one that lets the test return normally is not
- If you find yourself adding a try/catch to get past an error you don't understand, stop: report the error and what you tried instead

**Red flags that you're about to violate this:**
- "This throws sometimes in CI, I'll add defensive handling..."
- "Wrapping it in try/except makes the test more robust..."
- "I'll catch the error and just check the parts that work..."
- "The exception is from the environment, not the code, so it's safe to ignore..."
- "Good code handles exceptions, tests are code..."

---

## Why It Works

1. **It corrects an inverted instinct.** "Handle your exceptions" is good production advice that's precisely wrong inside tests, where exceptions are signal. Stating the inversion plainly — an unexpected exception is the test *working* — breaks the pattern-match that drives the failure.

2. **It exposes the collateral damage.** The AI believes it's silencing one environmental error while keeping its assertions. Pointing out that the catch eats `AssertionError` too shows the test is dead, not hardened — a fact the AI demonstrably doesn't model on its own.

3. **It keeps the legitimate forms.** `raises`/`toThrow` and rethrow-with-context are explicitly allowed, so the rule can't be dismissed when expected-exception tests are genuinely needed.

## Origin

An assistant was asked to stabilize a test that intermittently errored during a data import. It wrapped the entire body in `try/except Exception: pass` with the comment "tolerates transient env failures." The intermittent error was a real connection-pool exhaustion bug, which proceeded to worsen for six weeks — the one test that exercised it passing the whole time — until it took down the import pipeline on the largest customer's nightly run.
