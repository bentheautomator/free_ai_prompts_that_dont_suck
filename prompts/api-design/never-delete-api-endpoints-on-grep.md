---
title: Never Delete API Endpoints Based on Grep
slug: never-delete-api-endpoints-on-grep
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: critical
one_liner: "Stops deleting endpoints with no internal callers when external callers exist"
---

# Never Delete API Endpoints Based on Grep

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from removing an endpoint because nothing in the repo calls it — the definition of an API being that callers live elsewhere.

**[Copy-paste ready version](../../install/never-delete-api-endpoints-on-grep.md)** — just the instruction block, no explanation.

## The Problem

During a cleanup pass, the AI finds a route like `POST /v1/exports/csv`, greps the repository for callers, finds none, and deletes the handler, the route registration, and the tests. The reasoning is airtight inside the repo: unreferenced code is dead code. But an API endpoint with zero internal references isn't dead — it's *working as designed*. The entire point of exposing an HTTP endpoint is that its callers are somewhere else: a partner's cron job, a customer's script, an old mobile build, a Zapier integration someone configured in 2022.

The failure announces itself as a wave of 404s in other people's systems. Depending on the caller, that's a partner integration down, a customer's automation silently failing, or — for callers that don't check status codes — corrupted downstream state. Restoring the endpoint is usually easy; discovering *that this is what broke*, from outside reports, is not.

Assistants fall into this because dead-code elimination is one of their most reinforced behaviors, and every tool they have for verifying liveness — grep, reference search, call graphs — measures only the repository. For an HTTP boundary, that's measuring the wrong side.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Delete API Endpoints Based on Grep

NEVER delete, unregister, or stop serving an API endpoint because no code in this repository calls it. Zero internal references is the normal, expected state of a public endpoint — its callers are external HTTP clients that no code search can see.

- This covers every form of removal: deleting the handler, removing the route registration, dropping it from the router, commenting it out, or excluding it during a framework migration or router rewrite.
- Evidence that does NOT justify removal: no internal callers, no references in the frontend, no mention in recent commits, "legacy" or "old" or "deprecated" in the name, an empty-looking handler.
- Evidence that COULD justify removal — and only a human can confirm it: access logs showing zero traffic over a long window, a completed deprecation process with announced sunset, or the user explicitly confirming no external consumers exist.
- When migrating frameworks or rewriting routing, enumerate every route the old code served and verify the new code serves all of them. A route lost in migration is a deletion.
- If the user asks to remove an endpoint, ask whether external consumers were checked (logs, API gateway metrics, partner docs), state that removal 404s every external caller immediately, and suggest a 410-with-sunset-header deprecation period instead of an instant 404.

**Red flags that you're about to violate this:**
- "Nothing in the codebase calls this route, so it's dead."
- "It's named /legacy/ — clearly it was meant to be removed."
- "I searched the frontend too; no fetch calls hit this path."
- "The new router covers all the endpoints that actually matter."
- "Removing it shrinks the attack surface, so deletion is the safe choice."

---

## Why It Works

1. **It inverts the meaning of zero references.** The AI reads "unreferenced" as "dead"; the instruction redefines it as "externally consumed," which is the correct prior for anything exposed over HTTP.
2. **It separates inadmissible evidence from admissible evidence**, so the AI can't substitute a more thorough grep for the access logs it doesn't have.
3. **It catches migration-shaped deletions**, where endpoints vanish not by decision but by omission from a rewritten router — the most common real-world vector.
4. **It routes the removal impulse into a process** (traffic check, sunset, 410), so the AI has a correct action available instead of a forbidden one.

## Origin

Asked to "remove dead code before the audit," an assistant deleted four route handlers with no internal callers, including `GET /v2/inventory/feed`. That feed was polled hourly by a logistics provider whose client treated 404 as "empty inventory" and dutifully zeroed out stock levels across every warehouse it managed. Orders kept arriving for items the system now believed didn't exist. The endpoint was restored in minutes once identified; the stock reconciliation ran for a week.
