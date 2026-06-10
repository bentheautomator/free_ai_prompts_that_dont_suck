---
title: Never Rename API Response Fields
slug: never-rename-api-response-fields
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: critical
one_liner: "Stops field renames like user_id to userId that break every consumer at once"
---

# Never Rename API Response Fields

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming response fields "for consistency" and silently breaking every client that parses them.

**[Copy-paste ready version](../../install/never-rename-api-response-fields.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to "clean up" an API handler and there's a decent chance it renames `user_id` to `userId`, `created_at` to `createdAt`, and `acct_no` to `accountNumber` along the way. The diff looks like pure improvement: more consistent, more idiomatic, better aligned with the rest of the codebase. The tests it can see still pass, because it updated those too.

What it can't see is the mobile app shipped eight months ago, the partner integration, and the data pipeline that all deserialize `user_id` by name. Every one of them now gets `undefined`. There is no compile error and no 500 — the response is still valid JSON, just JSON that no existing consumer can read. These bugs surface as support tickets, not stack traces.

AI assistants do this because their entire visible world is the repository. Inside the repo, the rename looks complete and safe. The consumers it just broke don't exist in its context window, so consistency wins over a compatibility constraint it never saw.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Rename API Response Fields

NEVER rename a field in an API response, even if the new name is more consistent, more idiomatic, or objectively better. A field name in a shipped response is a contract with consumers you cannot see: mobile apps, partner integrations, scripts, and pipelines that parse it by exact name.

- Do not rename fields to match casing conventions (`user_id` → `userId`), fix typos (`recieved_at` → `received_at`), or improve clarity (`amt` → `amount`). All of these break deserialization in every existing client.
- If a better name is genuinely needed, add the new field alongside the old one and return both. Mark the old field deprecated in docs/OpenAPI. Removal happens later, by a human, on a deprecation schedule — not in this change.
- Updating the repo's own tests, types, and clients does not make a rename safe. The consumers that matter are the ones not in this repository.
- Internal variable names, database columns, and private DTOs can be renamed freely — the rule applies only at the serialization boundary, the moment a name appears in a response body.
- If the user explicitly asks to rename a response field, do it, but state plainly that it is a breaking change for any external consumer and suggest the add-alongside-and-deprecate path.

**Red flags that you're about to violate this:**
- "While I'm here, I'll make the field names consistent with the rest of the API."
- "I updated every usage in the codebase, so nothing is broken."
- "It's just a casing change, clients probably handle both."
- "This field name is a typo; fixing it is obviously correct."
- "The frontend in this repo is the only consumer."

---

## Why It Works

1. **It reframes a field name as a promise, not a style choice.** The AI's default frame is "code quality," where renames are improvements. Naming the invisible consumers moves the decision into "contract," where renames are breakage.
2. **It kills the strongest rationalization explicitly.** "I updated every usage" is the exact thought that precedes this failure; the instruction says out loud that repo-wide updates prove nothing about external clients.
3. **It provides the compatible alternative.** Without an additive path (return both, deprecate the old), the AI sometimes treats "don't rename" as "don't improve anything." The escape hatch keeps it productive.
4. **It scopes the rule to the serialization boundary**, so the AI doesn't overcorrect and refuse to rename local variables or internal types.

## Origin

A developer asked their assistant to "tidy up the orders endpoint before we document it." The assistant normalized eleven snake_case response fields to camelCase, updated the repo's own integration tests, and produced a green build. Three external consumers — a warehouse system, a finance export, and a partner's storefront plugin — started reading `undefined` for order totals that night. The fix took twenty minutes; identifying which of the eleven renames each consumer tripped on took most of a week.
