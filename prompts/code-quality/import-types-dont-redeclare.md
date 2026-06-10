---
title: Import Types, Don't Redeclare Them
slug: import-types-dont-redeclare
category: code-quality
tags: [universal, types, duplication]
works_with: all
severity: high
one_liner: "AI redefining a local copy of a type that already exists in the codebase"
---

# Import Types, Don't Redeclare Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from declaring local duplicate types instead of importing the canonical definitions.

**[Copy-paste ready version](../../install/import-types-dont-redeclare.md)** — just the instruction block, no explanation.

## The Problem

The project has a `User` interface in `types/user.ts` — twenty fields, carefully maintained, imported in forty places. An AI writing a new component needs a user, so it declares one at the top of the file: `interface User { id: string; name: string; email: string }`. Three fields, locally invented, structurally "close enough" that TypeScript's structural typing lets data flow between the two definitions without complaint — right up until it doesn't.

Models do this because declaring inline is generative flow and finding the canonical type is a search task, and also because a local declaration is guaranteed to compile while an import path has to be correct. The duplicate then leads its own life. The canonical `User` gains a `deletedAt` field; the local one doesn't, so the new component happily renders soft-deleted users. Someone refactors `id` to a branded type; the local `string` version now admits any string. In Python the same failure looks like a redeclared `@dataclass` or a second Pydantic model with a subset of fields, drifting from the schema that actually validates the API. Every duplicate type is a fork of the data model, and forks of the data model are how two parts of one app disagree about what a user *is*.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Import Types, Don't Redeclare Them

NEVER declare a type, interface, schema, or model for a domain concept that the codebase already defines. Find the canonical definition and import it. A local redeclaration is a fork of the data model that drifts from the original.

Structural typing makes the fork invisible at first — your three-field `User` interoperates with the real twenty-field one — which is exactly why it survives review and bites later.

**Before declaring any type:**
- Search for the concept's name (`User`, `Order`, `Invoice`, plus the codebase's actual domain vocabulary) in type directories, `types/`, `models/`, `schemas/`, `interfaces/`, shared packages, and generated-types output
- Domain concepts (entities, API payloads, config shapes, events) get imported, always — local declaration of these is forbidden even when you only need three of the fields
- Need a subset or variant? Derive it from the canonical type — `Pick<User, 'id' | 'name'>`, `Partial<Order>`, `Omit<...>`, extending the base model — so the link to the source of truth survives
- Types generated from a schema (OpenAPI, GraphQL codegen, Prisma, protobuf) are *especially* off-limits to redeclare: regeneration updates the real ones and leaves your copy behind
- Genuinely local shapes — a one-off props interface, an internal helper's tuple — are fine to declare; the rule is about concepts that exist beyond your file

**Red flags that you're about to violate this:**
- "I'll just define the fields I need right here..."
- "A quick local interface keeps this file self-contained..."
- "Their User type has too much stuff; mine is leaner..."
- "I don't know where their types live, faster to declare it..."
- "It's structurally compatible, so it doesn't matter..."
- Typing `interface User` or `class Order` without having searched for those names first

---

## Why It Works

1. **It names structural compatibility as the camouflage.** The AI (and the reviewer) sees the duplicate type *working* and concludes it's fine. Explaining that compatibility is precisely what hides the fork converts "it compiles" from reassurance into a warning.

2. **It channels the legitimate need into derivation.** "I only need three fields" is usually true — and `Pick` satisfies it while preserving the link to the canonical type. Giving the AI the right tool removes the main excuse for the wrong one.

3. **It draws the domain/local line.** A blanket "never declare types" would be absurd and ignored. Scoping the ban to concepts that exist beyond the current file keeps it followable, which keeps it followed.

4. **It singles out generated types.** Codegen output is where redeclaration hurts most — the schema moves, the copies don't — and where the AI is most tempted, because the generated names are long and the files are awkward to find.

## Origin

A dashboard feature shipped with a locally declared `Subscription` interface — five fields out of the canonical fourteen. Months later, billing added a `status` of `past_due` to the real model and gated features on it everywhere. The dashboard's fork had hardcoded the status union as `'active' | 'cancelled'`, so its type guard quietly filtered out past-due accounts and showed them full premium features. Revenue noticed before engineering did.
