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
