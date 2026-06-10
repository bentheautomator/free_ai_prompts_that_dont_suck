---
title: Keep UI State Local, Not Global
slug: keep-ui-state-local-not-global
category: frontend
tags: [universal, frontend, state]
works_with: all
severity: medium
one_liner: "Stops every toggle and input from being hoisted into the global store"
---

# Keep UI State Local, Not Global

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from putting component-local concerns — open/closed flags, input drafts, hover state — into the global store because a store exists.

**[Copy-paste ready version](../../install/keep-ui-state-local-not-global.md)** — just the instruction block, no explanation.

## The Problem

Give an AI assistant a codebase with Redux, Zustand, or a context-based store, and it treats the store as the default home for every new piece of state. A dropdown's open flag becomes `ui.dropdowns.headerNavOpen`. A search input's draft text becomes a global slice with its own actions. A modal's visibility gets a reducer, an action creator, and a selector — three files of ceremony for a boolean that one component reads.

The cost isn't just ceremony. Global state outlives the component: navigate away and back, and the dropdown is mysteriously still open, the form still holds a half-typed draft from another record, the modal reopens on mount. Every keystroke in that global search input re-renders every subscriber to the store slice. And the store becomes an attic of dead flags nobody dares delete, because nothing tracks which components still read them.

Assistants do this because the existing store is the most visible state pattern in the codebase, and "consistency with existing patterns" is their strongest instinct. Hoisting state also feels safe — global state is reachable from anywhere, so it can never be in the *wrong* place, only in too big a place. Nobody reviews a working dropdown for where its boolean lives.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It replaces a vibe with a countable test.** "Does a second distant consumer exist right now?" is answerable; "is this state shared?" invites the AI to imagine hypothetical consumers and answer yes.
2. **It names lifetime as the real bug, not style.** The AI treats local-vs-global as taste; pointing at stale-drafts-on-remount and zombie-open modals makes the wrong choice a concrete defect.
3. **It pre-empts the consistency rationalization.** "The codebase uses a store" is the single most common justification, and the rule explicitly declines it as a reason.
4. **It defuses speculative hoisting by pricing the alternative.** Stating that lifting state later is mechanical removes the "better safe than sorry" argument for globalizing now.

## Origin

A team's assistant added a quick-filter panel to a list view and, matching house style, stored the panel's open flag, draft filter text, and highlighted row index in the global store. Weeks later users reported the list page "remembering" a filter draft from a different project and highlighting a row that didn't exist — the state outlived navigation, and the cleanup action only fired on one of three exit paths. The patch that fixed it was moving three values into `useState` and deleting 140 lines of store plumbing.
