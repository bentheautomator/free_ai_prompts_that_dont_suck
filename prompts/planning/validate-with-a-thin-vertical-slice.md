---
title: Validate With a Thin Vertical Slice
slug: validate-with-a-thin-vertical-slice
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "Building every layer to completion before anything crosses all of them once"
---

# Validate With a Thin Vertical Slice

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents serializing a feature layer-by-layer when one end-to-end sliver would validate the whole design early.

**[Copy-paste ready version](../../install/validate-with-a-thin-vertical-slice.md)** — just the instruction block, no explanation.

## The Problem

Given a feature that spans layers — schema, API, client, UI — assistants default to horizontal construction: finish the entire schema, then the entire API, then the entire client. Each layer is completed in full before the next begins, which means the first moment anything travels through *all* the layers is at the very end. Every cross-layer mistake — an ID that should have been a compound key, an auth context the API needs but the schema can't provide, a latency profile the UI can't tolerate — stays invisible until the most expensive possible moment, with every layer fully built on top of it.

The alternative costs nothing extra: build vertically first. One narrow path through every layer — one entity, one endpoint, one screen, the simplest real case — working end to end before any layer gets widened. The slice is a design probe: it forces every interface to actually meet its neighbor while each layer is still ten lines instead of a thousand, and it produces a demoable, feedback-ready artifact on day one instead of day five.

Horizontal feels efficient because each layer is built in one focused pass. That efficiency is real and it is dwarfed by what it defers: integration risk, design errors, and user feedback all pile up at the end, compounding.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Validate With a Thin Vertical Slice

ALWAYS get one thin path working end to end before building any layer to completion. For multi-layer features, the first milestone is a sliver that touches every layer — one entity, one endpoint, one button, the simplest real case, actually running.

The core problem: building layer-by-layer means nothing crosses all the layers until the end, so every cross-layer design error survives until maximum-cost discovery.

- Plan the slice explicitly as step one: name the single case it covers ("create one task, see it in the list — no edit, no delete, no filters").
- Thin means narrow, not fake: real schema, real endpoint, real UI for the one case. Mocked layers don't validate seams; that's the point of the slice.
- Run it and, when feasible, show it. A working sliver is the cheapest possible artifact for the user to react to — corrections arrive while everything is still small.
- Only after the slice works, widen: more fields, more endpoints, more states. Widening a validated design is the safe, parallelizable part.
- If the slice is hard to build, that's the discovery working — the difficulty was going to surface anyway, and it just surfaced at minimum size.

**Red flags that you're about to violate this:**
- "I'll finish the whole data layer first since I'm in that headspace..."
- "It's more efficient to do each layer in one pass..."
- "I'll connect everything once all the pieces are solid..."
- "The user can review it when the feature is complete..."
- "End-to-end can wait; the layers are independent anyway..." (then why do they share a feature?)

---

## Why It Works

1. **It moves seam validation to minimum size.** Every interface mismatch costs its depth times what's built on it. The slice forces all seams to close while each layer is ten lines, making every mismatch a ten-line fix.

2. **It produces feedback bait.** Users can't react to a finished data layer; they react instantly to one working button. The slice converts "review my plan" (weak signal) into "try this" (strong signal) at the start, when course corrections are nearly free.

3. **It front-runs the integration pile-up.** Horizontal construction defers all integration to the end, where it compounds. The slice spends a small amount of integration early to make the rest of it incremental.

## Origin

A reporting feature was built horizontally: full warehouse schema week one, full aggregation API week two, then the dashboard — where the first real end-to-end request took 40 seconds, because the schema's grain forced the API to aggregate at query time. A one-chart slice in week one would have hit the same 40 seconds with two tables and one endpoint built, and the fix (pre-aggregated rollups) would have reshaped the schema before it was load-bearing. Instead the schema was rebuilt under three weeks of dependent code.
