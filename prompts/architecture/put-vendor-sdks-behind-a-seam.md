---
title: Put Vendor SDKs Behind a Seam
slug: put-vendor-sdks-behind-a-seam
category: architecture
tags: [universal, architecture, coupling]
works_with: all
severity: high
one_liner: "One vendor's SDK types and calls hardwired through fifty files"
---

# Put Vendor SDKs Behind a Seam

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from importing a vendor's SDK directly throughout the codebase, so that the vendor's types, errors, and API shape colonize code that should never know the vendor exists.

**[Copy-paste ready version](../../install/put-vendor-sdks-behind-a-seam.md)** — just the instruction block, no explanation.

## The Problem

The task is "send a notification," and the AI imports the vendor's SDK right there in the handler. Next task, another file, another `import stripe` / `from twilio.rest import Client` / `boto3.client(...)`. Each import is the shortest path to working code. A year later the vendor's SDK is imported in fifty-three files, its exception types are caught in thirty, its response objects are passed around as if they were domain types, and its client is constructed in eleven different ways with eleven different timeout settings.

The bill arrives in three currencies. Vendor SDK major-version upgrades become codebase-wide migrations instead of one-file changes. Testing requires mocking the vendor's API surface in every test file that touches the feature — and vendor SDKs are famously hostile to mocking. And when the pricing changes or the vendor sunsets the product (they do), "switch providers" is a rewrite estimate instead of a reimplementation of one seam. Note what this rule is not: it's not "abstract everything" — your web framework and your standard library don't need seams. It's that *replaceable third-party services* should be replaceable, which they aren't when their SDK is load-bearing in fifty files.

AI assistants hardwire vendors because the SDK's quickstart is the training data, and the quickstart's job is maximum adoption: import us everywhere, as directly as possible.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Put Vendor SDKs Behind a Seam

NEVER import a vendor service SDK (payments, email, SMS, storage, analytics, LLM APIs) outside the one module that owns that integration. The rest of the codebase calls the seam — a project-owned module with project-shaped functions — and never sees the vendor's types.

A vendor imported in fifty files isn't a dependency, it's an organ; the seam keeps it an appliance.

- One module per integration (`payments/stripe_gateway.py`, `notifications/email.py`): SDK imports, client construction, auth, retries, and vendor config all live there and only there
- The seam's functions speak the project's language — take and return your domain types or plain values, never the vendor's response objects; translate vendor exceptions into your error types at the seam
- Before adding a vendor import, grep for existing ones: if the seam exists, use it; if scattered imports exist, use or create the seam for your call and don't add scatter point fifty-four
- Don't pre-build a multi-provider abstraction with interfaces and factories — the seam is just the single place the vendor is touched, not a speculative provider framework
- Infrastructure SDKs used AS infrastructure (your web framework, your database driver inside the data layer) don't need this; the rule covers swappable external services, not your foundation
- Vendor-managed config (API keys, endpoints) is read inside the seam, not threaded through callers

**Red flags that you're about to violate this:**
- "The quickstart shows calling the SDK right from the handler..."
- "It's one API call, routing it through another module is bureaucracy..."
- "Other files already import the SDK directly, so it's the pattern..."
- "We'll never switch vendors anyway..."
- "I'll catch their SDK's exception type here, it's more specific..."

---

## Why It Works

1. **It bounds the blast radius by construction.** SDK upgrades, breaking changes, and provider swaps are one-module events when imports are confined — the cost scales with the seam, not the codebase.

2. **It makes the type boundary do the policing.** "Callers never see vendor types" is mechanically checkable (grep the imports) and prevents the subtle leak — vendor response objects drifting inward as de facto domain types.

3. **It splits seam from speculation.** The classic objection is "you're building an abstraction for a switch that never comes"; the rule asks only for *containment*, which pays for itself in testing and upgrades even if you stay with the vendor forever.

4. **It exploits the grep-first habit.** Scattered vendor imports grow one precedent-following import at a time; making the existing-seam check explicit interrupts the copying loop at its trigger.

## Origin

A startup's SMS vendor announced an API sunset with nine months' notice. The SDK was imported in 47 files; its message-object type appeared in function signatures in 19 of them, including the domain layer; three different retry strategies wrapped it in different corners. The migration to the new provider took two engineers eleven weeks, of which the new provider's actual integration took four days — the rest was extracting the old vendor from places it should never have been. The seam they built during the migration made the *next* vendor change, two years later, a one-sprint task.
