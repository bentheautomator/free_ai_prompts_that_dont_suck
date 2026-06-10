---
title: Clean Up Listeners, Timers, and Subscriptions
slug: clean-up-listeners-timers-and-subscriptions
category: performance
tags: [universal, performance, memory]
works_with: all
severity: high
one_liner: "Stops leaks from event listeners and timers that are added but never removed"
---

# Clean Up Listeners, Timers, and Subscriptions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from registering event listeners, intervals, and subscriptions without the matching teardown, leaking memory and ghost work for the life of the process.

**[Copy-paste ready version](../../install/clean-up-listeners-timers-and-subscriptions.md)** — just the instruction block, no explanation.

## The Problem

`addEventListener` without `removeEventListener`. `setInterval` without `clearInterval`. `emitter.on()` in a function that runs per request. A store subscription in a component with no unmount cleanup. Each registration captures a closure, the closure captures its scope, and the emitter or timer keeps everything reachable forever. Every time the registering code runs again, another copy stacks up. After a day of navigation or a week of uptime, the process holds thousands of live handlers, each firing on every event — memory grows, CPU grows, and behavior gets weird as stale handlers act on dead state.

AI assistants leak this way because registration is where the feature lives and teardown is where nothing visible happens. The happy-path demo works perfectly with one leaked listener; tutorials and training examples overwhelmingly show `on` without `off`. The assistant completes the task the moment the handler fires, and lifecycle is somebody else's paragraph.

The classic tell in production: a Node service whose heap climbs linearly with uptime, or a single-page app that gets slower the longer the tab stays open, plus the `MaxListenersExceededWarning` everyone has learned to ignore.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Clean Up Listeners, Timers, and Subscriptions

NEVER register a callback on something that outlives the registering scope without writing the matching teardown in the same change. Every `on`/`addEventListener`/`subscribe`/`setInterval`/`setTimeout`-that-reschedules must have a paired `off`/`removeEventListener`/`unsubscribe`/`clearInterval` wired to the owner's lifecycle.

A registration on a long-lived object (global emitter, window, document, store, socket, scheduler) pins the callback and everything its closure captures until explicitly removed. Re-running the registering code stacks duplicates.

- Write the cleanup at the same moment as the registration: return the unsubscribe function, use the framework's disposal hook (unmount/destroy/dispose effect cleanup), or use `AbortController`/`once` where supported.
- Be suspicious of any subscription created per request, per render, per reconnect, or per retry. Those paths run many times; each run must remove what the last run added or you accumulate one handler per execution.
- Keep a reference to the exact handler you registered. An inline anonymous function cannot be removed later.
- Timers that reschedule themselves need an owned cancel path; check a disposed flag before rescheduling.
- Verify by exercising the lifecycle: mount/unmount or connect/disconnect the thing 100 times and confirm handler counts and heap return to baseline (`getEventListeners`, `listenerCount()`, heap snapshot). One pass through the happy path proves nothing about accumulation.

**Red flags that you're about to violate this:**
- "The component rarely unmounts, so cleanup doesn't matter."
- "Garbage collection will take care of it."
- "I'll add the teardown in a follow-up."
- "It's just one listener."
- "The framework probably cleans this up automatically."
- "Removing it needs a reference and the inline arrow is cleaner."

---

## Why It Works

1. **It pairs creation with destruction syntactically.** Demanding the teardown "in the same change" exploits the AI's strength at local pattern completion: register/unregister becomes one unit, like open/close.
2. **It corrects the GC misconception.** Stating explicitly that the emitter keeps the closure reachable removes the "garbage collection handles it" escape hatch, which is the single most common rationalization for this leak.
3. **It targets the multiplying paths.** Naming per-request, per-render, and per-reconnect registration directs attention to exactly where one missing `off` becomes ten thousand.
4. **It defines a leak test, not a vibe check.** "Run the lifecycle 100 times, counts return to baseline" is mechanically checkable and catches accumulation that a single happy-path run never will.

## Origin

A dashboard app subscribed to a websocket price feed in a chart component, with no unmount cleanup. Every navigation to the chart added another subscription; users who flipped between tabs all day accumulated hundreds. Each price tick then triggered hundreds of redundant re-renders, and the app earned a reputation for "getting slow in the afternoon." The fix was returning the unsubscribe function from the effect. Eight characters of `return` plus what was already there, found after two weeks of blaming the charting library.
