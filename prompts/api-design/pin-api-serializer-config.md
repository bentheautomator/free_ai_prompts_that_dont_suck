---
title: Pin API Serializer Config
slug: pin-api-serializer-config
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: critical
one_liner: "Stops global serializer setting flips that rename every field in every response"
---

# Pin API Serializer Config

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing global serialization settings — naming policies, null handling, date formats — that rewrite every payload the API emits in one line.

**[Copy-paste ready version](../../install/pin-api-serializer-config.md)** — just the instruction block, no explanation.

## The Problem

The most destructive API change available to an AI assistant is one line long. `PropertyNamingStrategy.SNAKE_CASE` added to a Jackson config, `json.NamingStrategy = CamelCase` in .NET, `exclude_none=True` on a Pydantic base model, a `JSON_SORT_KEYS` or date-format flag in a framework settings file — each rewrites the wire format of *every endpoint simultaneously*. Field names re-case across the whole API. Null fields vanish from every payload. Every timestamp changes format at once. No endpoint code appears in the diff.

This usually happens during plausible work: a framework upgrade where the AI "modernizes" config to current defaults, a serializer swap (Gson → Jackson, json → orjson) where the replacement's defaults differ subtly, or an explicit consistency request that the AI satisfies at the config level because it's the efficient place. Efficiency is the problem — one line of config is a breaking change multiplied by the number of endpoints, and it sails through review precisely because no response-building code changed.

The AI reaches for global config because it's trained to prefer the DRY fix. At a serialization boundary, the DRY fix is a broadcast-breaking change.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Pin API Serializer Config

NEVER change global serializer or framework settings that affect how existing API responses are rendered: property naming strategies, null/empty-field inclusion, date/time formats, enum rendering, key ordering with semantic effect, or pretty/compact structure changes that alter content. One config line rewrites every endpoint's wire format at once — it is the largest possible breaking change hidden in the smallest possible diff.

- Treat these as frozen once an API has shipped: naming policy (`SNAKE_CASE`/`CamelCase` strategies), `omit_empty`/`exclude_none`/`NON_NULL` inclusion, global date formats, enum-as-name vs enum-as-value, number-as-string flags.
- When upgrading or swapping serialization libraries, the new library must be configured to reproduce the OLD wire format exactly — not its own defaults, and not the new version's "improved" defaults. Migration guides list behavior changes; check them against your payloads.
- Verify by golden-file diff: capture real serialized responses from several representative endpoints before the change and byte-compare (or key/structure-compare) after. "The tests pass" is meaningless when the tests serialize with the same config you just changed.
- Scope any genuinely-wanted new convention to new surface area only: a separate serializer instance for new endpoints or the next API version. Global config changes apply to history, and history has consumers.
- If the user asks for an API-wide format change, spell out that this re-renames or re-shapes every field of every response for every consumer, and propose the versioned or opt-in route.

**Red flags that you're about to violate this:**
- "The framework's new default naming strategy is what the config should have been all along."
- "One config line is much cleaner than annotating every DTO."
- "I'm swapping serializers, but they're functionally equivalent."
- "Dropping null fields shrinks payloads — pure win."
- "All the serialization tests still pass after the upgrade."

---

## Why It Works

1. **It re-prices the one-line diff.** The AI correlates risk with diff size; stating that config multiplies across every endpoint replaces that heuristic with the correct one — blast radius, not line count.
2. **It invalidates the passing-test signal** for this specific change class: tests that serialize through the changed config are self-confirming, and naming that removes the AI's main false reassurance.
3. **It mandates golden-file comparison**, an external check that catches format drift the type system and test suite structurally cannot.
4. **It redirects the DRY instinct** to a scoped serializer for new surface area, preserving the consistency goal without touching shipped payloads.

## Origin

During a routine framework major-version upgrade, an assistant adopted the new recommended JSON config, which included a snake_case naming strategy the codebase had been overriding implicitly. Every camelCase field in a 60-endpoint API hit the wire as snake_case at the next deploy. Internal clients broke loudly within minutes; the quiet damage was a dozen partner integrations reading `undefined` into their systems for the hour before rollback. The post-incident fix was a pinned serializer config with a golden-file test — three hours too late.
