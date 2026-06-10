---
title: Never Remove API Enum Values
slug: never-remove-api-enum-values
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops renaming or deleting enum values that consumers match with exact strings"
---

# Never Remove API Enum Values

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming or removing enum/status values in API payloads that consumers switch on with exact string comparisons.

**[Copy-paste ready version](../../install/never-remove-api-enum-values.md)** — just the instruction block, no explanation.

## The Problem

Status strings look like vocabulary, so AI assistants edit them like prose. `"status": "shipped"` becomes `"SHIPPED"` to match a new enum convention; `"cancelled"` becomes `"canceled"` because the codebase standardized on American spelling; `"pending_review"` and `"awaiting_review"` get merged because they're "obviously the same state." Inside the repo, the AI updates the enum class, the database values or their mapping, and every internal comparison. Green build.

Outside the repo, consumers are running `if (order.status === "shipped")` and webhook handlers are switching on exact strings. A renamed value doesn't error — it falls through. The order that's actually shipped matches no branch, so the partner's system leaves it in limbo, or worse, hits a default branch that treats unknown statuses as failures and triggers refund logic. Casing changes are the most insidious version because humans reviewing the diff read `shipped` and `SHIPPED` as the same word. String comparison does not.

The AI does it because enum values look like internal identifiers — they're defined in an enum class, after all. But the moment a value has been serialized into a response or webhook, the exact string, byte for byte, is the contract.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Remove API Enum Values

NEVER rename, remove, re-case, or merge an enum or status value that appears in API responses, requests, or webhooks. Consumers compare these as exact strings; a changed value doesn't error, it falls through their switch statements into default branches with unintended behavior.

- The exact serialized string is the contract: `shipped` ≠ `SHIPPED` ≠ `Shipped`. Casing normalization, spelling fixes (`cancelled` → `canceled`), and convention alignment (`pending_review` → `PENDING_REVIEW`) are all breaking changes to a string matcher.
- Do not merge "duplicate" states. Two values that mean the same thing to you are two distinct branches in consumer code; collapsing them reroutes one of those branches without warning.
- Renaming the enum member in code is fine only if the *serialized* value is pinned (e.g., `SHIPPED = "shipped"`). When refactoring enums, check what actually leaves the building — including the framework's default enum serialization, which often emits the member name.
- For request enums, keep accepting every value you ever accepted; map old inputs to new internals server-side. For response enums, keep emitting the value consumers expect.
- Adding new enum values to responses is allowed but is a soft break for consumers with exhaustive matching — mention it in your summary so the user can communicate it.
- If a value truly must go, the path is: announce, map server-side from old to new for a deprecation window, then remove by human decision. Never as part of a cleanup diff.

**Red flags that you're about to violate this:**
- "I'm normalizing all status values to uppercase to match the enum convention."
- "These two statuses are redundant — consolidating them simplifies the state machine."
- "It's a one-letter spelling fix; no reasonable client breaks on that."
- "I updated the enum and the database migration, so the change is complete."
- "Status strings are internal vocabulary; the API just happens to expose them."

---

## Why It Works

1. **It locates the contract at the serialized byte level**, which dissolves the "same word, different casing" blind spot — the AI (and human reviewers) read semantically, but consumer code compares exactly.
2. **It names fall-through as the failure mode.** Renames don't produce errors, they produce *wrong branch execution*, which is why the AI's mental test ("would this throw?") passes while production breaks.
3. **It separates code identifiers from wire values**, giving the AI a legitimate way to satisfy its naming-convention urge: rename the member, pin the string.
4. **It covers both directions** (accept old inputs forever, emit expected outputs), preventing the half-fix where requests are handled but responses still change.

## Origin

A state-machine cleanup consolidated `payment_failed` and `payment_declined` into a single `payment_failed` value. A subscription-management consumer had distinct flows: declined cards got a retry-with-new-card email, hard failures got cancellation. Post-merge, every declined card fell into the hard-failure branch and cancelled the subscription on first decline. About six hundred customers were churned by a diff whose description was "simplify payment states — no functional changes."
