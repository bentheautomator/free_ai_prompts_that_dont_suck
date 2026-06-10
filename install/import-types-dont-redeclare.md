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
