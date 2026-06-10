---
title: Freeze API List Sort Order
slug: freeze-api-list-sort-order
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: medium
one_liner: "Stops changing the implicit ordering of list endpoints consumers rely on"
---

# Freeze API List Sort Order

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing the default ordering of a list endpoint — an undocumented property that consumers have quietly built logic on.

**[Copy-paste ready version](../../install/freeze-api-list-sort-order.md)** — just the instruction block, no explanation.

## The Problem

Hyrum's Law has a favorite victim, and it's sort order. A list endpoint has returned newest-first since launch — maybe by deliberate `ORDER BY created_at DESC`, maybe by accident of the primary key. Consumers noticed. One takes `items[0]` as "the latest." Another stops paginating when it sees a record older than its last sync. A dashboard renders the response in order, top item most prominent. None of this is in the docs, and all of it is load-bearing.

Then the AI optimizes the query, adds an index hint, rewrites the ORM call, or decides alphabetical order is friendlier — and the order changes. Nothing breaks visibly: same fields, same count, same 200. But `items[0]` is now the *oldest* record, the incremental sync terminates instantly (or never), and the dashboard surfaces stale entries as if they were news. The consumers' logic is wrong in a way that produces wrong *data*, not errors, which is the slowest kind of bug to find.

This one's special because the AI often changes ordering *without noticing*: removing a seemingly redundant ORDER BY during query cleanup, or switching to a query plan where insertion order no longer leaks through. Ordering is a contract that doesn't even appear in the response shape.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Freeze API List Sort Order

NEVER change the order in which an existing list endpoint returns items — including "undocumented" or accidental orderings. Consumers infer order guarantees from observed behavior: they take the first element as latest, terminate sync loops on order, and display results as received. A changed order produces wrong data with a 200, never an error.

- Do not remove or alter ORDER BY clauses during query optimization, ORM migrations, or cleanup — even ones that look redundant. If the old query had no explicit ordering but returned a stable de facto order, add an explicit ORDER BY that *preserves* the observed order rather than leaving it to a new query plan.
- Changing databases, indexes, or pagination internals can silently reorder results. After such changes, compare result order on real data against the previous behavior.
- Alphabetical, relevance, or "more sensible" default orderings are new features: ship them behind a `sort=` parameter, and make the parameter's absence return the historical order.
- Within paginated endpoints, ordering is also what keeps pages consistent — changing it mid-flight breaks consumers walking pages, duplicating or skipping records across the boundary.
- If the user explicitly wants a new default order, note which consumer patterns break (first-element-as-latest, order-based sync termination, display order) and suggest the sort-param route with the default unchanged.

**Red flags that you're about to violate this:**
- "This ORDER BY isn't required by anything in the code — removing it speeds up the query."
- "Alphabetical order is more user-friendly for this list."
- "The API never documented an order, so no order is guaranteed."
- "The new query returns the same rows; order is an implementation detail."
- "Consumers should sort client-side if they care about order."

---

## Why It Works

1. **It invokes observed behavior over documentation** — "no documented order" is the AI's strongest argument, and the rule pre-empts it by defining the contract as what consumers could observe and build on.
2. **It flags the unintentional vectors** (ORDER BY removal, query-plan changes), because most order breakage is a side effect the AI never registers as an API change at all.
3. **It classifies new orderings as features with an opt-in parameter**, giving the "better default" impulse a compatible shape.
4. **It connects ordering to pagination integrity**, surfacing the second-order failure (skipped/duplicated records across pages) that makes this more than a cosmetic concern.

## Origin

A query-optimization pass removed an ORDER BY that profiling showed was costing a sort on every request; the rows came back in index order instead, which on that table meant oldest-first. A client's sync job fetched pages until it saw a record it already had — previously a correct early-exit, now true on page one, every run. It synced nothing for three weeks while reporting success, and the gap was noticed only when someone asked why a new customer wasn't appearing in the downstream system.
