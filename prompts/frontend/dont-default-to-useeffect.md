---
title: Don't Default to useEffect
slug: dont-default-to-useeffect
category: frontend
tags: [universal, frontend, react]
works_with: all
severity: high
one_liner: "Stops effect chains doing work that belongs in render or event handlers"
---

# Don't Default to useEffect

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from routing logic through useEffect that belongs in render, event handlers, or memoization — the source of cascading re-renders and unfixable timing bugs.

**[Copy-paste ready version](../../install/dont-default-to-useeffect.md)** — just the instruction block, no explanation.

## The Problem

To an AI assistant, `useEffect` is the answer to "something should happen." Form value changed? Effect that validates. Need a transformed list? Effect that sets a second state variable. User submitted? Set a `submitted` flag, then an effect watches the flag and fires the request. Each effect works in isolation, and together they turn a component into a Rube Goldberg machine: state change triggers effect triggers setState triggers re-render triggers the next effect, with the actual logic smeared across reactive callbacks whose firing order depends on dependency arrays nobody fully audited.

The costs are concrete. Every effect-set-state pair is an extra render cycle, so the UI visibly double-flashes. Logic that should be a synchronous expression now runs a frame late, producing "the validation message shows the previous value" bugs. Event logic moved into effects loses its cause — an effect watching `selectedId` can't tell a user click from a programmatic reset, so the side effect fires on both. And dependency arrays become a minefield: add the missing dep, get an infinite loop; omit it, get stale closures.

The AI defaults to effects because "react to changes" sounds like what hooks are for, and because effect-heavy code dominates training data. The mental model it's missing: effects are for synchronizing with systems *outside* React. Inside React, render computes and events respond.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Default to useEffect

NEVER reach for `useEffect` until you've ruled out render and event handlers. Effects are for synchronizing with external systems (network, DOM APIs, subscriptions, timers) — not for reacting to your own state.

Each unnecessary effect adds a render cycle, a frame of staleness, and a dependency array to get wrong.

- Transforming data for display (filter, sort, derive, format): compute it in render. Expensive? `useMemo`. Never effect-plus-setState — that's a cache that can drift and double-renders by design.
- Responding to a user action (submit, click, select): put the logic in the event handler. Don't set a flag in the handler and have an effect watch the flag — that severs cause from effect and fires on every path that touches the flag, not just the user's action.
- Resetting state when a prop changes (e.g., new `userId` clears the form): pass `key={userId}` to remount, or derive what you can. An effect that mirrors props into state is two sources of truth.
- Notifying a parent of a change: call the callback in the event handler that caused the change, not in an effect watching the changed value.
- Legitimate effects: fetching on mount (when the project isn't using a data library), subscribing to events/stores/sockets, syncing to localStorage or document.title, driving non-React widgets. The test: does this synchronize React state with something outside React? If both ends are React state, it's not an effect.
- Before writing any effect, state which external system it synchronizes with. No external system, no effect.

**Red flags that you're about to violate this:**

- "When X changes, I need to update Y — that's a useEffect."
- "I'll set a flag on submit and let an effect do the actual work."
- "An effect keeps this derived list up to date."
- "I'll sync the prop into local state when it changes."
- "Chaining effects keeps each step small and clean."
- "The lint rule wants this dep, I'll add it — what loop?"

---

## Why It Works

1. **It replaces the trigger phrase with a test.** "When X changes, do Y" auto-completes to useEffect; "which external system does this synchronize?" has no answer for derived state and event logic, blocking the reflex.
2. **It names the flag-watching pattern as severed causality.** The submit-flag-plus-effect construction is the AI's favorite and looks principled; explaining that it fires on every flag mutation, not just user intent, exposes why it breeds bugs.
3. **It provides the non-obvious remount tool.** `key={userId}` for prop-driven resets is the idiomatic answer almost no AI produces unprompted — without it, the prop-mirroring effect is the only move it knows.
4. **It keeps the legitimate uses explicit.** A bare "avoid useEffect" rule causes the AI to contort genuinely external synchronization into worse shapes; the allowlist prevents overcorrection.

## Origin

A search page built by an assistant had six chained effects: query change set debouncedQuery, which set isSearching, which triggered the fetch, which set results, which set filteredResults, which updated resultCount. Typing one character produced five re-renders and a count that lagged the visible list by one keystroke — filed as "result count is always wrong." The rewrite was one event handler and one fetch, with everything else computed in render; five state variables and all six effects were deleted.
