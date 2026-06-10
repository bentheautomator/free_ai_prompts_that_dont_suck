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
