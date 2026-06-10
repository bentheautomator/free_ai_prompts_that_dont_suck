---
title: No CRUD Completionism
slug: no-crud-completionism
category: scope
tags: [universal, scope]
works_with: all
severity: high
one_liner: "AI building all four CRUD endpoints when one was requested"
---

# No CRUD Completionism

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "completing the set" with endpoints, methods, and operations nobody requested.

**[Copy-paste ready version](../../install/no-crud-completionism.md)** — just the instruction block, no explanation.

## The Problem

Ask for a `GET /api/teams/:id` endpoint and there's a decent chance you'll receive the full set: GET, POST, PUT, PATCH, and DELETE, each with serializers and routes, because the AI saw a resource and instinctively gave it a complete REST interface. The same completionism shows up elsewhere: asked for a `read_config()` function, it writes `write_config()` to match; asked for an `encrypt()`, a `decrypt()` arrives alongside; one event handler becomes handlers for the whole lifecycle.

Symmetry feels like thoroughness, but every unrequested operation is live, reachable functionality with no requirement behind it — which means nobody specified its behavior, nobody reviewed its implications, and nobody is testing it. An unrequested DELETE endpoint is the standout offender: it's a destructive operation, often wired with whatever auth the AI guessed, discoverable by anyone who enumerates the API. The requested GET got review attention; the bonus DELETE got merged in its shadow. Unused write paths also have a discovery problem in reverse: monitoring won't mention them, docs won't cover them, and the first caller will be someone you didn't plan for.

When the team genuinely wants the full resource interface, that's five minutes of asking. When it doesn't, the "complete" version is attack surface shipped as garnish.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No CRUD Completionism

Build the operations the request names and no others. NEVER complete a set (CRUD, getter/setter, encode/decode, open/close) because the requested piece implies siblings.

The core problem: unrequested operations are reachable functionality with no specification, no review attention, and no tests, and the destructive ones among them are unaudited attack surface.

- "Add a GET endpoint" produces one endpoint; do not scaffold POST/PUT/PATCH/DELETE alongside it
- Never add unrequested destructive or mutating operations (delete, update, write, send); these carry authorization and data-loss implications that demand explicit requirements
- The same applies to function pairs and lifecycle sets: a requested `serialize()` does not license a `deserialize()`; one handler does not license the full event set
- Do not stub the siblings either; a stubbed-but-routed endpoint is still reachable surface, and a commented-out one is still diff noise
- Inverse operations are in scope only when the requested piece is unusable without them (rare, and if so, say which and why)
- If completing the set seems obviously intended, ask in one line: "Want the other CRUD operations too, or just the GET?" One question beats four unreviewed endpoints

**Red flags that you're about to violate this:**
- "A resource needs full CRUD, so I'll scaffold all of it..."
- "They'll want the delete endpoint eventually, might as well..."
- "Read without write feels incomplete..."
- "The framework generates all the routes anyway, free thoroughness..."
- "I'll stub the others so the structure is in place..."
- "Symmetry makes the API more predictable..."

---

## Why It Works

1. **It severs implication from specification.** The AI infers requirements from symmetry ("GET implies the rest"); declaring that siblings need their own request removes the inference rule producing the creep.

2. **It singles out destructive operations.** A bonus DELETE is categorically worse than a bonus GET; giving mutations their own NEVER prevents the worst case even if the AI fudges the rest.

3. **It closes the stub loophole.** "I'll just scaffold them unimplemented" preserves the surface-area problem while feeling compliant; banning routed stubs by name blocks the halfway version.

4. **It substitutes a one-line question.** The AI may be right that the full set is wanted; pricing the alternatives ("one question beats four unreviewed endpoints") makes asking the obviously dominant move.

## Origin

A request for a read-only endpoint to power a dashboard widget shipped with a complete CRUD set, including a DELETE guarded only by the default logged-in check, because the assistant mirrored the auth from the GET. Months later a security researcher's report demonstrated that any authenticated user could delete any record of that type by ID. The fix took an hour; the disclosure handling, customer notifications, and audit of every other AI-scaffolded endpoint took a quarter.
