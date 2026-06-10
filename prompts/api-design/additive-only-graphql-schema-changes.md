---
title: Additive-Only GraphQL Schema Changes
slug: additive-only-graphql-schema-changes
category: api-design
tags: [universal, apis, graphql]
works_with: all
severity: high
one_liner: "Stops removing or renaming GraphQL fields that deployed queries select"
---

# Additive-Only GraphQL Schema Changes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from removing or renaming GraphQL fields, types, and enums that deployed client queries reference by name.

**[Copy-paste ready version](../../install/additive-only-graphql-schema-changes.md)** — just the instruction block, no explanation.

## The Problem

GraphQL's flexibility on the read side hides total rigidity on the schema side. A client query is a literal list of field names — `query { user { fullName company { name } } }` — compiled into apps, persisted-query manifests, and partner code. The moment the AI renames `fullName` to `displayName`, deletes a "redundant" type, or collapses `Company` into `Organization` during a schema cleanup, every deployed query selecting the old name stops validating. And GraphQL fails harder than REST here: an unknown field doesn't come back as a missing key, it makes the *entire query* return errors. One renamed field can blank an entire screen.

There's a special trap in the tooling. Code-first frameworks derive the schema from resolver classes, so an innocent-looking rename of a Python or TypeScript method *is* a schema change — the AI refactors what looks like internal code and ships a breaking schema diff without ever opening a `.graphql` file.

Assistants do this because schemas accumulate genuine mess — duplicated types, inconsistent names — and cleaning that mess is exactly what they're asked to do. The deployed queries that pin every name in place live in client bundles the AI will never see.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Additive-Only GraphQL Schema Changes

NEVER remove or rename anything in a shipped GraphQL schema: fields, types, enums, interfaces, unions, or query/mutation names. Deployed client queries reference these by exact name, and a single unknown field fails the entire query — one rename can blank a whole app screen, including in client versions that can never be updated.

- Schema evolution is addition-only: add new fields next to old ones, add new types, add new enum values (cautiously), add new queries/mutations. The old names keep resolving.
- To replace a field, add the successor, mark the old one `@deprecated(reason: "Use displayName")`, and leave it functional. Deprecated-but-working is the correct end state of this change; actual removal is a later, human-scheduled step driven by field-usage metrics.
- In code-first schemas (type-graphql, Strawberry, graphene, Nexus, gqlgen), resolver and class renames ARE schema renames. Before renaming any resolver-adjacent identifier, check whether it surfaces in the SDL; if it does, pin the schema name explicitly while renaming the code.
- Changing a field's return type (`String` → custom scalar, object → union, singular → list) breaks selection sets and generated client types just like a removal. Same rule: new field, deprecate old.
- If the user explicitly asks for a removal, ask whether field-level usage metrics confirm zero traffic, and note that unlike REST, clients fail at query validation — partial tolerance is not available.

**Red flags that you're about to violate this:**
- "These two types are nearly identical; merging them simplifies the schema."
- "I renamed the resolver method, but that's just a code-level refactor."
- "The schema is versionless, so cleanups like this are how GraphQL evolves."
- "Our own frontend doesn't query this field — I checked the .graphql files."
- "The deprecation has been there for ages; clearly it's time to delete."

---

## Why It Works

1. **It states GraphQL's failure amplification** — one unknown field errors the whole query — replacing the AI's REST-derived intuition that consumers degrade gracefully around missing data.
2. **It closes the code-first trap by name**, where the breaking change wears the costume of an internal refactor and no schema file appears in the diff.
3. **It defines deprecated-but-working as the finish line**, countering the AI's drive for tidy completion, which otherwise treats lingering deprecated fields as unfinished work.
4. **It extends the rule to type changes**, which break generated clients identically to removals but look like improvements rather than deletions.

## Origin

During a "schema hygiene" pass, an assistant merged two near-duplicate types and renamed four fields to consistent camelCase, updating the web app's queries in the same monorepo. The mobile apps shipped their queries inside compiled binaries; every install in the field began receiving validation errors on the home query, rendering an empty feed. Forcing an app-store-paced fix for a server-side rename took two weeks of dual-schema shimming that the deprecation path would have made unnecessary.
