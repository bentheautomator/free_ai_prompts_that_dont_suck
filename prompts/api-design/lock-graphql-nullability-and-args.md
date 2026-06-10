---
title: Lock GraphQL Nullability and Arguments
slug: lock-graphql-nullability-and-args
category: api-design
tags: [universal, apis, graphql]
works_with: all
severity: high
one_liner: "Stops non-null flips and new required args that invalidate deployed queries"
---

# Lock GraphQL Nullability and Arguments

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from flipping GraphQL nullability markers or making arguments required — changes that look like one-character schema tweaks and break clients in both directions.

**[Copy-paste ready version](../../install/lock-graphql-nullability-and-args.md)** — just the instruction block, no explanation.

## The Problem

In GraphQL, a single `!` is a contract clause, and AI assistants edit them like punctuation. The trap is that *both directions* break someone. Make `email: String` into `String!` and the schema now promises non-null — until one row lacks an email, the resolver returns null anyway, and non-null propagation destroys the parent object or the entire response for every client, over one field on one record. Relax `name: String!` to `String` and generated clients (Apollo codegen, Relay, graphql-codegen) regenerate the type from non-optional to optional, breaking compilation in every consumer repo — while older deployed clients keep assuming non-null and crash at runtime on the first null.

Arguments and input types have the same knife-edge: adding a required argument to an existing query, or adding a required field to an input type, invalidates every deployed operation that doesn't pass it. The queries are compiled into apps and persisted-query allowlists; they cannot start sending the new argument retroactively.

The AI flips these because nullability looks like a data-modeling annotation — "email is always present, so `String!` is more accurate" — rather than what it is: a load-bearing promise wired into codegen and the null-propagation algorithm.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Lock GraphQL Nullability and Arguments

NEVER change nullability markers (`!`) on existing GraphQL fields, and NEVER add required arguments or required input-type fields to shipped queries and mutations. Both directions of a nullability flip break consumers, and required additions invalidate every deployed operation that predates them.

- Nullable → non-null (`String` → `String!`) is a runtime bomb: the first resolver null triggers non-null propagation, erroring the parent selection or the whole response for all clients because of one bad record.
- Non-null → nullable (`String!` → `String`) breaks generated client types in every consumer that runs codegen, and deployed clients built against non-null crash on the first null they were promised would never come.
- New arguments on existing fields/queries must have defaults or be nullable. New fields on existing input types must be optional. Deployed operations are frozen text — often in persisted-query allowlists — and cannot retroactively send anything.
- Tightening an input the resolver genuinely needs is done in the resolver: validate at runtime, return a typed error for new violations, and keep the schema signature stable. Schema-level tightening waits for a new field or schema version.
- If asked to "make the schema match reality" by adding `!`, first confirm the data can never be null (including legacy rows and failure paths), and present the flip to the user as a breaking change for codegen consumers regardless.

**Red flags that you're about to violate this:**
- "This field is never actually null, so marking it non-null just documents reality."
- "Codegen consumers will simply regenerate their types — that's what codegen is for."
- "The mutation needs this argument now; old clients should be passing it anyway."
- "Loosening to nullable can't break anyone — it accepts strictly more."
- "It's a one-character schema change."

---

## Why It Works

1. **It explains non-null propagation**, the mechanism the AI doesn't model: a `!` doesn't just describe data, it instructs GraphQL to escalate one null into response-wide failure.
2. **It breaks the "loosening is safe" symmetry assumption** — true for many type systems, false under codegen, and naming codegen makes the second direction's breakage concrete.
3. **It treats deployed operations as frozen text**, which is the fact that makes required-argument additions impossible to absorb, persisted queries being the sharpest case.
4. **It relocates tightening to the resolver**, giving the AI a place to enforce the new requirement that doesn't touch the contract.

## Origin

Confident that every account had a verified email, an assistant changed `email: String` to `String!` while adding a profile feature. A batch of imported legacy accounts had null emails; each one nulled out its entire `user` object via propagation, and the member directory — which listed users in pages of fifty — errored whenever any page contained one legacy account. The visible symptom was "random pages of the directory are blank," which took two engineers a day to connect to a one-character schema diff.
