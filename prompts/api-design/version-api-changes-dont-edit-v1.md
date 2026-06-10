---
title: Version API Changes, Don't Edit v1
slug: version-api-changes-dont-edit-v1
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops breaking changes being edited into the version consumers already use"
---

# Version API Changes, Don't Edit v1

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from implementing a breaking change by editing the existing API version in place instead of creating a new version next to it.

**[Copy-paste ready version](../../install/version-api-changes-dont-edit-v1.md)** — just the instruction block, no explanation.

## The Problem

The user asks for a real change: "the search endpoint should return grouped results instead of a flat list." That's legitimately breaking, and the user may even know it. The failure is in *where* the AI implements it. The codebase has `/v1/search`; the AI edits the v1 handler. The version number in the URL keeps promising stability while the behavior underneath it changes — which is worse than having no versioning at all, because consumers specifically pinned `/v1/` to be insulated from exactly this.

The same failure has a subtler costume: shared code. The v1 and v2 handlers both call `SearchService.format_results`, and the AI implements v2's new behavior by modifying the shared method — silently dragging v1 along. Or the codebase has versioning machinery the AI ignores because adding `/v2/search` feels heavyweight for "one endpoint change," so it slips the new behavior into v1 as the path of least resistance.

AI assistants default to in-place editing because that's what code change means everywhere else in software: you don't copy a function to modify it. APIs are the exception — the old behavior must keep existing because its callers keep existing — and that exception has to be stated.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Version API Changes, Don't Edit v1

When a requested change to an API endpoint is breaking — different response shape, different semantics, removed or changed behavior — NEVER implement it by editing the existing version in place. A version number in the path (`/v1/`) is a stability promise; changing behavior under it betrays exactly the consumers who pinned it.

- Breaking changes go in a new version: `/v2/endpoint` alongside `/v1/endpoint`, or the project's equivalent (header versioning, date-based versions). The old version keeps its exact current behavior, served by code that still exists.
- Check before assuming: if the codebase already has a versioning scheme, use it. If it has none, surface the question to the user — "this change is breaking; should I add it as a new versioned endpoint or change it in place?" — rather than silently choosing in-place.
- Watch shared internals: modifying a service, formatter, or serializer that multiple versions call changes ALL versions. Implementing v2 must not reach through shared code into v1's behavior — fork or parameterize the shared path so v1's output is bit-for-bit unchanged.
- "Copy, then modify the copy" is correct engineering at a version boundary, even though it feels like duplication. The duplication is the feature: it's what lets v1 stand still.
- Version inflation is also real: do not spin up a new version for changes that are purely additive (new optional fields, new endpoints). Versions are for breaks.

**Red flags that you're about to violate this:**
- "Creating a whole new version for one endpoint change is overkill."
- "The user asked for the new behavior — they didn't mention keeping the old one."
- "I'll just update the shared formatter; both versions get the improvement."
- "v1 is old anyway; surely everyone is meant to be on the new behavior."
- "Duplicating this handler violates DRY."

---

## Why It Works

1. **It inverts the default meaning of "change."** In-place modification is correct everywhere except a versioned boundary; stating the exception explicitly is necessary because all of the AI's training pulls the other way.
2. **It names the shared-code leak**, the mechanism by which v1 breaks even when nobody edits a v1 file — the most common way this failure survives code review.
3. **It rehabilitates duplication at the boundary**, directly countering the DRY instinct that otherwise makes copy-then-modify feel like malpractice.
4. **It includes the anti-inflation clause**, so the AI doesn't overcorrect into versioning every additive tweak and eroding the team's tolerance for the rule.

## Origin

Asked to make a quoting endpoint return itemized tax breakdowns "instead of a single tax field," an assistant rewrote the response builder that `/v1/quotes` used — the only version that existed, pinned in the config of two partner storefronts because the integration docs said v1 was stable. Both partners' checkout flows broke on the missing `tax` field within the hour. The eventual fix was exactly what should have shipped initially: a `/v2/quotes` with breakdowns, v1 restored untouched, and a migration note — plus an apology call that didn't need to happen.
