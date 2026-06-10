---
title: Never Import the Data Layer From UI
slug: never-import-the-data-layer-from-ui
category: architecture
tags: [universal, architecture, layering]
works_with: all
severity: high
one_liner: "UI code importing repositories or DB clients, skipping the service layer"
---

# Never Import the Data Layer From UI

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wiring UI components straight to repositories, ORMs, or database clients when a service layer exists in between.

**[Copy-paste ready version](../../install/never-import-the-data-layer-from-ui.md)** — just the instruction block, no explanation.

## The Problem

A component needs one extra field that the service layer doesn't currently expose. Instead of adding it to the service, the AI imports `userRepository` (or the ORM model, or the raw DB client) directly into the view and queries for it. The data appears on screen, the diff is three lines, and the task looks done.

What actually happened: the UI is now coupled to the database schema. Every authorization check, cache, tenant filter, and soft-delete rule that lives in the service layer just got bypassed for this one read. The next schema migration breaks a screen nobody thought was related to the database. And because the shortcut exists, it gets copied — the second and third direct imports cite the first one as precedent.

AI assistants take this shortcut because the layered path requires editing two or three files (service method, maybe a DTO, then the component) while the direct import requires one. Single-file diffs feel surgical. The cost is invisible in the diff and enormous in the dependency graph.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Import the Data Layer From UI

NEVER import repositories, ORM models, query builders, or database clients into UI code (components, views, pages, templates, frontend route files). UI talks to the service/API layer; only the service layer talks to data.

A direct UI-to-data import bypasses every rule the service layer enforces (authz, caching, tenant scoping, soft deletes) and welds screens to the database schema.

- If the UI needs data the service layer doesn't expose, extend the service layer: add the field to an existing method or add a new method, then call that from the UI
- Do not import ORM entities into components "just for the type"; use or create the DTO/view-model type the service layer returns
- Do not copy an existing direct import you find in the UI; one violation is a bug, not a precedent
- Server-rendered frameworks count: page loaders, `getServerSideProps`-style functions, and template helpers go through services too, not straight to the ORM
- If no service layer exists at all in this codebase, follow whatever its actual boundary is; this rule is about skipping a layer that exists, not inventing one

**Red flags that you're about to violate this:**
- "It's just one field, going through the service is ceremony..."
- "I'll query the repository directly here and clean it up later..."
- "Another component already imports the model, so it's the pattern..."
- "This is a read-only call, the service layer rules don't matter for reads..."
- "Adding a service method means touching three files for a one-line change..."

---

## Why It Works

1. **It prices the shortcut correctly.** The AI sees a three-line diff; the rule names what the diff actually buys: bypassed authz, caching, and scoping, plus schema coupling. That reframes "surgical" as "leaky."

2. **It kills precedent-laundering.** "One violation is a bug, not a precedent" blocks the most common justification, which is pointing at an existing bad import.

3. **It handles the type-only excuse.** Importing an ORM entity for its type is the gateway violation; the rule names it and supplies the alternative (the DTO the service returns).

4. **It defines the correct move, not just the banned one.** "Extend the service layer" turns the rule from a wall into a route, so the AI doesn't stall or invent a third option.

## Origin

A dashboard widget needed a "last login" timestamp, and an assistant imported the user ORM model into the component to fetch it. The query skipped the service method that filtered out deactivated accounts, so the widget happily displayed data for users who had deleted themselves, which surfaced in a privacy review. By then four more components had copied the import, and removing the schema coupling from the UI took longer than the original feature.
