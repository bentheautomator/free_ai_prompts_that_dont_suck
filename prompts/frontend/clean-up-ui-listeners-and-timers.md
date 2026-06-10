---
title: Clean Up UI Listeners and Timers
slug: clean-up-ui-listeners-and-timers
category: frontend
tags: [universal, frontend, react]
works_with: all
severity: high
one_liner: "Stops leaked listeners, intervals, and subscriptions from unmounted components"
---

# Clean Up UI Listeners and Timers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from registering window listeners, intervals, observers, and subscriptions without tearing them down on unmount.

**[Copy-paste ready version](../../install/clean-up-ui-listeners-and-timers.md)** — just the instruction block, no explanation.

## The Problem

The setup half of every subscription is where the feature lives, so that's the half AI assistants write. `useEffect(() => { window.addEventListener('resize', onResize) }, [])` — no return statement. A `setInterval` polling for status — never cleared. A `ResizeObserver`, a WebSocket `onmessage`, a store subscription — attached on mount, orphaned on unmount. The feature works the first time the component mounts, which is the only time the AI evaluates it.

Then the user navigates. The component unmounts; its listeners don't. The resize handler now runs against a dead component, calling `setState` on something unmounted (warning, or silent wasted work) or — nastier — closing over stale props and mutating things it shouldn't. Navigate back and forth five times and five resize handlers fire on every resize, five intervals poll the API in parallel, and the WebSocket handler appends each message to five different stale closures. The symptoms are heisenbugs: duplicate toasts, doubled analytics events, memory climbing in long sessions, "the modal sometimes closes itself." Nothing points back to the unmount that didn't clean up.

In React 18+ dev mode, StrictMode double-invokes effects specifically to surface this — so the missing cleanup also manifests as "works in prod build, broken in dev," which AIs then "fix" by removing StrictMode.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Clean Up UI Listeners and Timers

EVERY subscription, listener, timer, and observer you create in a component must be torn down when the component unmounts. Setup without teardown is a leak, written at the exact moment you have everything needed to prevent it.

- The effect pattern is symmetric — whatever the setup does, the cleanup undoes:
  `addEventListener` → return `removeEventListener` (same target, same function reference — a re-created inline arrow won't remove);
  `setInterval`/`setTimeout` → `clearInterval`/`clearTimeout` the saved id;
  `new IntersectionObserver/ResizeObserver/MutationObserver` → `disconnect()`;
  socket/store/emitter `.subscribe`/`.on` → the returned unsubscribe or `.off`.
- Write the cleanup in the same edit as the setup. "It works without it" is true only for the first mount of a session.
- Fetches in effects: handle the unmounted case — `AbortController` aborted in cleanup (preferred) or an ignore flag — so a slow response doesn't set state on a corpse or, worse, resolve into the *next* mount's state.
- Event handlers added to `document`/`window` from open-state UI (modals' Escape handlers, click-outside listeners) must be removed when the UI closes, not just on unmount — tie the effect to the open state.
- If the effect re-runs (non-empty dependency array), cleanup runs between executions: confirm the teardown makes re-subscription safe, or you'll stack one subscription per dependency change.
- Never delete StrictMode or its double-invoke to make a symptom disappear — double-firing effects in dev is the leak detector telling you a cleanup is missing.

**Red flags that you're about to violate this:**

- "I'll add the listener now; cleanup is polish."
- "Empty dependency array means it only runs once, so nothing to clean up."
- "The component basically never unmounts."
- "Effects firing twice in dev is a React quirk — I'll remove StrictMode."
- "The interval is cheap, a stray one won't hurt."
- "I'll remove the listener with a fresh arrow function of the same code."

---

## Why It Works

1. **It pairs setup and teardown as one atom.** The leak exists because the two halves feel like separate tasks with separate urgency; "same edit" removes the gap where the second half evaporates.
2. **It gives the per-API teardown table.** "Clean up your effects" fails when the AI doesn't know that observers want `disconnect()` and that `removeEventListener` needs the identical function reference — the mechanics are the rule.
3. **It reframes StrictMode double-invocation as the test, not the bug.** AIs routinely respond to the symptom by deleting the detector; naming that move forecloses it.
4. **It covers re-running effects and aborted fetches.** Mount/unmount is the case everyone states; deps-change re-subscription and late-resolving fetches are where the remaining leaks actually live.

## Origin

A dashboard's assistant added a status poller — `setInterval` hitting the API every five seconds — to a widget, with no cleanup. Every visit to the dashboard stacked another interval that survived navigation. Users who kept the app open all day accumulated dozens of concurrent pollers; the API team noticed when one customer's traffic graph showed requests growing linearly through each session, resetting only on page reload. The fix was a one-line `return () => clearInterval(id)`, found after two days of investigating "the API DDoSing itself."
