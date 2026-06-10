---
title: Derive UI State, Don't Store It
slug: derive-ui-state-dont-store-it
category: frontend
tags: [universal, frontend, state]
works_with: all
severity: high
one_liner: "Stops storing computable values in state where they go stale"
---

# Derive UI State, Don't Store It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from storing values that can be computed from existing state, creating copies that drift out of sync.

**[Copy-paste ready version](../../install/derive-ui-state-dont-store-it.md)** — just the instruction block, no explanation.

## The Problem

A component has `items` in state, and the task needs a filtered list. The AI adds `const [filteredItems, setFilteredItems] = useState([])` plus a `useEffect` that recomputes it when `items` or `query` change. It needs a count: `const [itemCount, setItemCount] = useState(0)`, another effect. A "has unsaved changes" flag: stored boolean, set in four places, forgotten in the fifth. Each one is a cached copy of something that could be a plain expression, and each one is a sync obligation the AI just signed the whole codebase up for.

The drift is the bug. The copy is correct on the render the AI tested and wrong on the code path it didn't write — the new delete handler updates `items` but not `filteredItems`, so a deleted row keeps rendering. The stored count says 12 while the list shows 11. The effect-based sync also costs an extra render per change and turns simple data flow into a graph of cascading effects that fire in an order nobody can predict.

Assistants do this because "I need a value across renders, values across renders live in state" is a shallow pattern match, and because `useState` + `useEffect` is the most reinforced combination in their training data. The derived expression — `const filteredItems = items.filter(...)` — is shorter, but it doesn't look like "managing state," so it doesn't get reached for.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Derive UI State, Don't Store It

NEVER store a value in state that can be computed from existing state or props during render. Compute it where it's used; state is only for things that cannot be derived.

Every stored copy of derivable data is a synchronization bug waiting for the one code path that forgets to update it.

- Filtered/sorted/mapped lists: `const visible = items.filter(...)` in render. Not a second state variable synced by an effect.
- Counts, totals, flags: `const isEmpty = items.length === 0`, `const hasChanges = draft !== original`. Expressions, not state.
- Selection: store the selected `id`, derive the selected object (`items.find(i => i.id === selectedId)`). Storing the object means it goes stale when the item updates.
- If the computation is genuinely expensive, memoize it (`useMemo`, `computed`) — memoization is derivation with a cache, and it cannot drift. Don't reach for it preemptively; most filters over UI-sized lists are free.
- The pattern `useState` + `useEffect` that only calls the setter from values already in scope is the tell. If an effect's only job is keeping state B in sync with state A, delete state B.
- Legitimate state: user input, fetched data, and anything that can't be recomputed from what you already have. If you can write the value as a pure function of other state, it isn't state.

**Red flags that you're about to violate this:**

- "I'll keep filteredItems in state and update it when the filter changes."
- "I need this value in two places, so it should be state."
- "An effect can keep the count in sync with the list."
- "Storing the selected object saves a lookup."
- "Recomputing on every render feels wasteful."
- "I'll add state for this now and make sure to update it everywhere."

---

## Why It Works

1. **It gives a decision test that doesn't require judgment.** "Can you write it as a pure function of existing state?" has a yes/no answer; "should this be state?" gets answered by pattern-matching to useState.
2. **It names the sync-effect smell explicitly.** An effect whose only body is a setter fed by in-scope values is mechanically detectable, so the AI can catch itself in the act.
3. **It answers the performance objection before it's raised.** "Recomputing is wasteful" is the rationalization that keeps copies alive; pointing at `useMemo` as drift-proof caching removes it.
4. **It covers the selection trap specifically.** Storing selected objects instead of ids is the variant that produces stale-data bugs invisible until an item updates elsewhere, and generic phrasing misses it.

## Origin

An assistant built a searchable member list: members in state, plus `filteredMembers` in state, synced by an effect watching the query. A later task added inline role editing, which updated `members` — but the edit was invisible until the user typed in the search box, because nothing retriggered the filter sync. QA filed it as "edits randomly not saving." The fix deleted the second state variable and the effect, replacing both with one `.filter()` call in render.
