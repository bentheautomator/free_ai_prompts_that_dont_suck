---
title: Don't Leak ORM Entities Through Domain Interfaces
slug: dont-leak-orm-entities-through-domain-interfaces
category: architecture
tags: [universal, architecture, boundaries]
works_with: all
severity: high
one_liner: "ORM entities and HTTP request objects crossing the domain boundary"
---

# Don't Leak ORM Entities Through Domain Interfaces

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from threading ORM entities, HTTP request objects, and other infrastructure types through domain signatures, quietly coupling the core to every framework at the edges.

**[Copy-paste ready version](../../install/dont-leak-orm-entities-through-domain-interfaces.md)** — just the instruction block, no explanation.

## The Problem

The AI needs to pass user data into a domain service. The ORM entity is already loaded, it has all the fields, and the type checker is happy — so the signature becomes `calculate_renewal(user: models.User)`. One signature later, the domain layer imports the ORM. Now the pricing logic can't be tested without a database session, lazy-loading fires mid-calculation, and swapping or upgrading the ORM means touching the business rules. The same move happens at the other edge: a service that takes `req: Request` because the handler had it in hand.

This is the laziest possible interface, which is exactly why AI assistants produce it: the infrastructure object is the value that already exists, and converting it to a plain type is "extra code." The cost is invisible in the diff. It surfaces months later, when every domain test needs fixture machinery for a framework the logic never cared about, and when the entity's 40 fields make it impossible to tell which three the function actually reads.

Infrastructure types are also unstable in exactly the wrong way. ORMs change session semantics between versions; web frameworks reshape request objects. A domain layer built on plain values absorbs none of that churn. A domain layer built on `models.User` absorbs all of it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Leak ORM Entities Through Domain Interfaces

NEVER put infrastructure types — ORM entities, database rows, HTTP request/response objects, framework context objects, message-queue payloads — in the signature of a domain function, service method, or domain interface. Domain code takes and returns plain values and domain types.

Every infrastructure type in a domain signature couples the core to a framework it shouldn't know exists, and drags that framework into every test of the logic.

- Convert at the boundary: the handler/repository maps the entity or request into a domain object (or plain parameters) before calling domain code, and maps the result back on the way out
- A repository's public methods return domain types, not ORM entities; the entity stays inside the repository file
- Passing the entity "because it has all the fields" is the trap — list the fields the function actually uses and pass those; the narrow signature is documentation
- Don't subclass or duck-type around it (a domain type that inherits from the ORM base class is still the ORM)
- If the codebase already passes entities everywhere, follow its convention for this task and note the coupling in your summary — but never extend the leak into a module that is currently clean

**Red flags that you're about to violate this:**
- "The entity already has every field I need, mapping is busywork..."
- "I'll just take the request object so I don't have to pick parameters..."
- "It's basically a data class, the ORM base class doesn't really count..."
- "Defining a separate domain type duplicates the model..."
- "The test can just spin up SQLite, it's fast enough..."

---

## Why It Works

1. **It assigns the conversion to a specific place.** "Map at the boundary" answers the question the AI otherwise resolves by not converting at all — someone concrete (handler, repository) owns the translation.

2. **It converts a vague principle into a type-level check.** "No infrastructure types in domain signatures" is verifiable by reading the imports of the domain module; either `models` and `Request` appear or they don't.

3. **It reframes the narrow signature as information.** A function taking three named values tells the reader what it depends on; a function taking the whole entity tells them nothing — the rule makes that legibility argument available against the "busywork" excuse.

4. **It distinguishes following a leak from extending one.** Codebases with existing entity-passing exist; the carve-out keeps the rule from being ignored as unrealistic while still ratcheting toward clean modules.

## Origin

A reporting module's core aggregation function took a live ORM entity, and a field access deep inside the math triggered a lazy load — one query per row, 14,000 rows, every night. The fix attempt was harder than expected: the function touched eleven entity fields across three relations, and nobody could enumerate them without tracing every line. Once it was rewritten to take a plain dataclass with five fields, the N+1 was structurally impossible and the test suite dropped its database dependency entirely.
