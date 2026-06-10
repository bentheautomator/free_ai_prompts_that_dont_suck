---
title: Always Await Async Assertions
slug: always-await-async-assertions
category: testing
tags: [universal, testing, async]
works_with: all
severity: critical
one_liner: "Unawaited async expectations that pass before the result ever arrives"
---

# Always Await Async Assertions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents async tests that finish before their assertions run, passing no matter what the code does.

**[Copy-paste ready version](../../install/always-await-async-assertions.md)** — just the instruction block, no explanation.

## The Problem

This test passes even if `validateUser` resolves successfully with garbage:

```javascript
it('rejects invalid users', () => {
  expect(validateUser(badUser)).rejects.toThrow(ValidationError);
});
```

The missing `await` (and missing `async`) means the test function returns before the promise settles; the runner sees a completed test with no failed assertions and scores it green. The rejection assertion is genuinely evaluated — later, against nobody, its failure either swallowed or surfacing as an unhandled-rejection warning that scrolls past in the noise. The same vacuum hides in many shapes: calling an async function without awaiting it and asserting on the unstarted result, `forEach(async ...)` which awaits nothing by design, a Python coroutine called without `await` in a non-async test (which "passes" while emitting a never-awaited warning), assertions placed in a `.then()` callback the test doesn't return.

AI assistants produce these because the code is one keyword away from correct and reads almost identically — and because their verification is "the test passed," which is precisely the signal this bug counterfeits. An unawaited assertion isn't a weak test; it's a test whose verdict is rendered before the evidence arrives.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Always Await Async Assertions

Every asynchronous operation in a test must be awaited before the test ends. An unawaited `expect(...).rejects`/`resolves`, an unreturned promise chain, or an unawaited coroutine means the test completes before the result exists — and a test that finishes before its assertions run passes unconditionally.

The core problem: the runner scores "function returned, nothing failed" as green. Asynchrony makes that state trivially reachable with zero assertions actually evaluated, and the broken version is one missing keyword away from the correct one.

Rules:
- `expect(promise).rejects...` and `.resolves...` return promises: ALWAYS `await` them, inside an `async` test. Unawaited, they assert into the void
- Never call the async function under test without awaiting it (or explicitly asserting on the awaited result). `const result = fn()` followed by assertions tests a pending promise object, not the outcome
- `.then()`/`.catch()` chains in tests must be returned or replaced with await; assertions inside an unreturned callback run after the verdict
- `forEach(async ...)` awaits nothing — use `for...of` with await, or `await Promise.all(items.map(...))`
- Python: a coroutine called without `await` never executes; use an async test (pytest-asyncio or equivalent) and await every coroutine. Treat any "coroutine was never awaited" warning in test output as a failing test, not noise
- Heed the runner's hints: Jest's "test finished but async operations are pending" class of warnings, unhandled rejection messages, open-handle reports — each is this bug announcing itself
- Verification that the test tests: break the code's behavior deliberately (make the function resolve when it should reject) and confirm the test goes red. An async test you've never seen fail has not yet earned trust

**Red flags that you're about to violate this:**
- "The rejects matcher handles the promise internally..."
- "The test passes, so the assertion must have run..."
- "I'll fire the calls in a forEach and assert after..."
- "That never-awaited warning is unrelated noise..."
- "Adding async/await everywhere is just ceremony for a one-liner test..."

---

## Why It Works

1. **It explains the runner's scoring rule.** The AI assumes the framework would notice an assertion that never ran. Stating the actual contract — returned-without-failure equals pass — reveals why this bug is invisible to the only signal the AI checks.

2. **It enumerates the disguises.** Missing await on matchers, unreturned chains, `forEach(async)`, unawaited coroutines — the same vacuum wears different syntax per ecosystem. The list converts one abstract rule into recognizable concrete patterns.

3. **It mandates seeing the test fail.** Mutating the behavior and watching for red is the only direct proof an async test is wired to its verdict. This check defeats the counterfeit green that every other check trusts.

4. **It upgrades warnings to failures.** "Never awaited" warnings are the bug self-reporting, and the AI's instinct is to scroll past. Reclassifying them as test failures captures the free diagnostic.

## Origin

An access-control suite contained nineteen tests of the form `expect(checkAccess(...)).rejects.toThrow(Forbidden)` — none awaited, all green since the day they were generated. A permissions refactor inverted a condition, and `checkAccess` began resolving for users it should have rejected; all nineteen tests kept passing, their assertions evaluating after each test had already closed its books. The hole was found when someone finally investigated the wall of "unhandled promise rejection" warnings that had decorated every test run for months — the suite had been failing, in detail, into a channel nobody read.
