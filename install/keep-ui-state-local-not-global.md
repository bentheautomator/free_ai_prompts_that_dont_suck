### Keep UI State Local, Not Global

NEVER put state in the global store unless more than one distant part of the app reads it. Default to component-local state; hoist only when a second consumer actually exists.

The global store is for shared state. A dropdown's open flag, an input's draft value, a hover or focus flag — these have one consumer, and putting them in the store gives them the wrong lifetime and re-render scope.

- Open/closed, expanded/collapsed, hovered, focused, active-tab-within-a-widget: `useState` (or the framework's local equivalent) in the component that renders it.
- Form drafts: local to the form (or the form library's own state) until submitted. Globalizing drafts means stale text resurfaces when the user returns to the form for a different record.
- Hoist exactly as far as needed: two sibling components sharing state means lift to their parent, not to the store.
- "Some other component might need this someday" is not a second consumer. Hoist when the need exists, not speculatively — moving state up later is a mechanical refactor.
- Legitimate store residents: the authenticated user, theme, cross-page selections, anything a deep-linked or distant component reads. If you can name the two distant consumers, it can go global.
- Don't mirror local state into the store "for debugging visibility" — that creates two sources of truth that drift.

**Red flags that you're about to violate this:**

- "This project uses Redux, so new state goes in Redux."
- "I'll put the modal flag in the store so anything can open it later."
- "Global state is easier to wire than passing one prop."
- "The store already has a ui slice, this fits right in."
- "Keeping all state in one place is cleaner architecture."
- "I'll sync the local value into the store too, just in case."
