---
title: Freeze API ID Formats
slug: freeze-api-id-formats
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: critical
one_liner: "Stops int-to-UUID and number-to-string ID changes that break stored references"
---

# Freeze API ID Formats

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing the type or format of identifiers an API exposes — integers to UUIDs, numbers to strings, raw IDs to prefixed ones.

**[Copy-paste ready version](../../install/freeze-api-id-formats.md)** — just the instruction block, no explanation.

## The Problem

Identifiers are the one value consumers don't just read — they *keep*. An `"id": 4821` from your API is sitting right now in someone else's database column typed as an integer, in a foreign-key-like reference, in a bookmark URL, in a cached lookup table. When an AI assistant migrates the model to UUIDs "for security," starts returning IDs as strings "because JavaScript mangles big integers," or adds a prefix scheme (`ord_4821`) borrowed from APIs it admires, it doesn't just change today's responses. It orphans every identifier ever handed out.

The breakage is double-ended. Responses with the new format fail consumers' type expectations — the strict ones reject the payload, the loose ones store `"ord_4821"` next to last year's `4821` and can no longer join the two. And the request direction is worse: consumers send back the IDs they stored, so `GET /orders/4821` must keep resolving *forever*, even if new orders get UUIDs. An ID change that doesn't honor old lookups breaks every stored reference in the world simultaneously.

The AI does this because ID format looks like a persistence-layer decision — and at the database layer, it is. The failure is letting the new internal format leak through the serialization boundary where the old format was already promised.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Freeze API ID Formats

NEVER change the type or format of identifiers in an existing API: integer → UUID, number → string, unprefixed → prefixed, or any change to length, casing, or structure. IDs are the only API values consumers store long-term — in their databases, URLs, and caches — so a format change breaks not just parsing but every reference already handed out.

- Both JSON type and format are frozen: `4821` (number) → `"4821"` (string) breaks typed deserializers even though the digits match. `"4821"` → `"ord_4821"` breaks everything that stored the bare value.
- Old IDs must resolve forever. Even with an internally migrated ID scheme, every endpoint that accepts an ID must keep accepting the previously-issued format and look it up correctly. An ID is a permanent ticket, not a current-schema artifact.
- Database/internal migrations (int PK → UUID) are acceptable only if the serialization boundary continues exposing and accepting the old external format — via a mapping table or dual-key lookup. The external ID and the storage key are allowed to be different things; keep them different.
- If a new format is genuinely required externally (e.g., enumeration concerns), expose it additively: a new `uuid` or `public_id` field next to `id`, with old lookups still honored, and flag the consumer-migration plan to the user.
- Numeric IDs approaching JavaScript's safe-integer limit are a real problem with the same answer: add a string twin field; do not mutate the existing field's type.

**Red flags that you're about to violate this:**
- "Sequential integer IDs are an enumeration risk; switching to UUIDs fixes it."
- "Returning IDs as strings is safer for JavaScript clients, so it's an improvement."
- "Prefixed IDs like cus_123 are industry best practice."
- "The migration maps every old ID to a new one, so nothing is lost."
- "Consumers treat IDs as opaque — format shouldn't matter to them."

---

## Why It Works

1. **It distinguishes stored values from read values.** The AI evaluates ID changes like any field change (can clients parse the new responses?), missing that consumers hold yesterday's IDs — naming that makes "old IDs resolve forever" an obvious requirement.
2. **It splits the external ID from the storage key**, dissolving the false constraint that a database migration must surface in the API. Most violations come from conflating the two.
3. **It pre-rebuts "IDs are opaque"** — opaque means consumers don't interpret them, not that the type and format can mutate under a stored copy.
4. **It legitimizes the motivations** (enumeration, JS integer limits) and routes each to an additive mechanism, so the security or correctness argument can't justify the in-place break.

## Origin

To stop ID enumeration, an assistant migrated order primary keys to UUIDs and updated the API to emit and accept only UUIDs, with a clean data migration. Every order reference outside the building — a shipping partner's database, customer support's saved links, emailed receipts with order URLs — held integer IDs that now returned 404. The shipping partner couldn't post status updates to existing shipments for three days until a dual-lookup shim went in, which is what the change should have been on day one.
