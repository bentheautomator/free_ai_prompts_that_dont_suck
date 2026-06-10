---
title: No Sleep-Based Flaky Test Fixes
slug: no-sleep-based-flaky-test-fixes
category: testing
tags: [universal, testing, flaky]
works_with: all
severity: high
one_liner: "AI adding sleep(5000) to a racy test instead of synchronizing it"
---

# No Sleep-Based Flaky Test Fixes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" timing-dependent tests by sprinkling sleeps that slow the suite and fix nothing.

**[Copy-paste ready version](../../install/no-sleep-based-flaky-test-fixes.md)** — just the instruction block, no explanation.

## The Problem

A test fails because it asserts before an async operation finishes. The correct fix is to wait *for the thing*: await the promise, poll for the condition, subscribe to the completion event. The AI's fix is to wait *for a while*: `await new Promise(r => setTimeout(r, 3000))`, `time.sleep(5)`, `Thread.sleep(2000)`. It reruns the test, the race happens to lose this time, and the AI reports the flake fixed.

It isn't fixed — the race is exactly as present as before; the sleep just changed the odds. On a slower CI runner, under parallel load, the same test fails again, and the established remedy is now "increase the sleep." Suites accrete these until they take forty minutes and still flake, at which point someone is asked to fix the flaky tests, and the cycle deepens. AI assistants default to sleeps because the failure superficially reads as "not enough time," and adding time is a one-line edit that usually survives the AI's own single verification run — the one run where the dice were rolled once and came up green.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Sleep-Based Flaky Test Fixes

NEVER fix a timing-dependent test failure by adding or increasing a fixed sleep (`sleep`, `setTimeout`-as-delay, `Thread.sleep`, `time.sleep`). Wait for conditions, not durations.

The core problem: a sleep doesn't remove a race, it re-handicaps it. The test still fails on slow machines and still wastes the full duration on fast ones — you've made the suite slower *and* kept the flake.

Instead:
- Await the actual operation: the promise, the task handle, the future. If you can't get a handle on it, that's the bug to fix
- Poll for the condition with a timeout: `waitFor(() => expect(el).toBeVisible())` (Testing Library), `await expect(locator).toHaveText(...)` (Playwright auto-waits), `eventually`/`awaitility`/tenacity-style helpers. These pass the instant the condition holds and fail loudly when it never does
- Use fake timers for code that schedules work (`jest.useFakeTimers()` then `advanceTimersByTime`), so the test controls time instead of racing it
- Synchronize via the system's own signals: completion callbacks, events, queue-drained hooks, database state checks
- If a sleep already exists and the test still flakes, do not raise the number. Find what the sleep was approximating and wait for that
- One legitimate sleep: when verifying that something does NOT happen within a window — and even then, prefer fake timers

**Red flags that you're about to violate this:**
- "It probably just needs a bit more time..."
- "I'll bump the sleep from 2s to 5s to be safe..."
- "A short delay here makes the test stable..."
- "It passed after I added the sleep, so that confirmed the fix..."
- "Polling is more complex, a sleep does the same job..."

---

## Why It Works

1. **It replaces a duration with a condition.** The AI's mental model — "the test needs more time" — is subtly wrong; the test needs *an event*. Reframing every sleep as a question ("what is this duration approximating?") points directly at the correct synchronization primitive.

2. **It invalidates single-run verification.** "It passed after I added the sleep" is statistically meaningless for a race, and the AI's workflow leans entirely on that one run. Saying so forces either a loop-run proof or the honest fix.

3. **It supplies the idioms.** Most sleeps exist because the AI didn't reach for `waitFor`/fake timers/auto-waiting assertions. Naming them per ecosystem makes the right thing as cheap as the wrong thing.

## Origin

A UI test suite for an order dashboard contained, at final count, 73 sleeps totaling four and a half minutes of guaranteed dead time per run — nearly all added by an assistant over months of "stabilizing" requests, several with comments like "increased from 3s, still flaky at 2s." The suite still failed about one run in six on loaded CI hardware. Converting the sleeps to condition waits took a day, cut the suite from 11 minutes to 4, and the flake rate went to zero, because the races had been in the tests' assumptions all along.
