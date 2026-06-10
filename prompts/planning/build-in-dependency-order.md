---
title: Build in Dependency Order
slug: build-in-dependency-order
category: planning
tags: [universal, planning]
works_with: all
severity: high
one_liner: "Building the UI first, then discovering the data model can't support it"
---

# Build in Dependency Order

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents building components in the order they're easiest to imagine instead of the order they depend on each other.

**[Copy-paste ready version](../../install/build-in-dependency-order.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to "add a tagging feature" and it will often start with the part it can visualize: the tag chips in the UI, the autocomplete dropdown, the filter bar. Two hundred lines later it gets to the schema and discovers tags need to be scoped per-workspace, which means the component props it just designed are wrong, which means the dropdown that consumed them is wrong, which means most of the morning is wrong.

The UI is the most demoable layer, so it gets built first. But demoability and dependency order are different orderings. The data model constrains the API, the API constrains the client state, the client state constrains the components. Build top-down and every discovery at a lower layer ripples back up as rework through everything above it.

The failure isn't visible until late, which is what makes it expensive. The UI-first version looks like rapid progress right up until the foundation contradicts it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Build in Dependency Order

ALWAYS build the layer that constrains before the layer that consumes. Data model before API, API before client state, client state before components. Never start with the most visible piece just because it is the easiest to picture.

The core problem: surface layers are the most demoable, so they get built first — and then every decision discovered at a lower layer invalidates work above it.

- Before starting a multi-layer feature, write the dependency chain: which piece defines the shapes that the other pieces consume? Start there.
- Design the schema or core types first and get them confirmed. They are the cheapest layer to change now and the most expensive to change later.
- If you want something visible early, stub the UI against the real types — don't design real UI against imagined types.
- When you must work top-down (e.g., the user hands you a mockup), extract the data requirements from the mockup and validate them against the model before writing components.
- Treat any "I'll figure out storage later" thought as a stop sign. Storage is where the constraints live.

**Red flags that you're about to violate this:**
- "I'll mock the data for now and wire it up at the end..."
- "The UI is the part the user will want to see first..."
- "The schema is basically obvious, I'll formalize it later..."
- "Let me get something on screen, then work backwards..."
- "The backend part is boring, I'll save it for last..."

---

## Why It Works

1. **It puts the constraining decisions first.** Lower layers define shapes; upper layers consume them. Decisions made in dependency order are made once. Decisions made in reverse order are made, discovered wrong, and remade.

2. **It converts late rework into early design.** A schema mistake found while writing the schema costs a sentence. The same mistake found through a finished UI costs every file between the UI and the schema.

3. **It gives the demo urge a safe outlet.** Stubbing real types into a placeholder UI satisfies "show me something" without committing component design to fictional data.

## Origin

An assistant built a notification preferences screen first: toggle grid, per-channel rows, polished. The schema, written last, revealed preferences were stored per-organization with user overrides — a two-level merge the flat toggle grid could not express. The components, their props, the API client, and the screen's state management were all rewritten. The schema, had it come first, would have dictated the right UI in one pass.
