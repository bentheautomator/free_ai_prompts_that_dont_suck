---
title: Never Rename API Endpoint Paths
slug: never-rename-api-endpoint-paths
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops URL path renames for consistency that 404 every external caller"
---

# Never Rename API Endpoint Paths

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming endpoint URLs — pluralizing, re-nesting, kebab-casing — and leaving every external caller pointed at a 404.

**[Copy-paste ready version](../../install/never-rename-api-endpoint-paths.md)** — just the instruction block, no explanation.

## The Problem

Route tables attract tidying. `/getUserOrders` is an RPC-style embarrassment in a RESTful API, so the AI renames it to `/users/{id}/orders`. `/order` should be plural like its siblings, so it becomes `/orders`. `/api/userProfile` gets kebab-cased to `/api/user-profile` for consistency with the style guide. The AI dutifully updates the repo's own clients and tests, and the route table finally looks like it was designed by one person on one day.

A URL, though, is the most widely copied string an API has. It's hardcoded in partner integrations, mobile builds, customers' scripts, saved Postman collections, and configuration files for systems nobody remembers. Unlike a field rename — which at least returns a response with the wrong shape — a path rename returns 404, the same response as "this never existed." Callers can't distinguish "moved for consistency" from "gone," and HTTP gives them no forwarding address unless someone deliberately builds one.

The AI renames paths because route definitions look like internal code organization — they're just strings in a router file. But each one is the public street address of a service, and external callers don't get a change-of-address card.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Rename API Endpoint Paths

NEVER rename, re-nest, re-case, or pluralize the URL path of an existing endpoint. A shipped path is hardcoded in external clients, configs, and saved tooling; renaming it turns every one of those references into a 404 that is indistinguishable from the endpoint never having existed.

- This includes every flavor of improvement: RPC-to-REST conversion (`/getUserOrders` → `/users/{id}/orders`), pluralization (`/order` → `/orders`), casing (`/userProfile` → `/user-profile`), re-nesting under new prefixes, and "fixing" inconsistent segment names.
- Updating all callers inside the repository proves nothing — the callers that break are the ones you cannot grep.
- If a better path is warranted, add it as an alias: register the new route AND keep the old route serving identical behavior (same handler), or return 301/308 redirects from the old path if all known clients follow redirects on the relevant methods (many HTTP clients do not follow redirects for POST/PUT by default — verify before relying on this).
- The old path stays until a human retires it through a deprecation process with usage metrics. "Both routes work" is the correct end state of your change, not an interim mess to clean up.
- Path *parameters* count too: changing `/orders/{order_number}` to resolve by internal ID instead of order number breaks every stored URL even though the route pattern looks identical.
- If the user explicitly asks for a rename, deliver it as alias-plus-new-path by default and say why; only remove the old route if they confirm no external callers exist.

**Red flags that you're about to violate this:**
- "This endpoint name doesn't follow REST conventions like the rest of the API."
- "I updated every fetch call in the codebase to the new path."
- "Singular /order was clearly a mistake — all the other resources are plural."
- "A redirect would be overkill; clients should just use the new URL."
- "I'm reorganizing the routes under a cleaner prefix structure."

---

## Why It Works

1. **It frames paths as street addresses, not code organization.** Router entries look like internal naming; calling them the most-copied string in the API puts external hardcoding front and center.
2. **It points out that 404 erases information** — callers can't tell a rename from a deletion, so there's no graceful degradation available, unlike most contract changes.
3. **It defines success as both-routes-working**, blocking the AI's completionist urge to delete the old route as "cleanup" in the same diff.
4. **It includes the redirect caveat** (POST doesn't follow by default), removing the false comfort that a 301 makes any rename safe.
5. **It covers parameter semantics**, the stealth version where the pattern survives but the meaning of the path segment changes.

## Origin

An assistant asked to "make the routes RESTful" renamed nine endpoints in one diff, including `/api/getInvoices` → `/api/invoices`. The repo's own dashboard was updated and worked perfectly. A bookkeeping integration used by several hundred customers had `/api/getInvoices` in its connector config; its sync began failing with 404s it logged as "remote endpoint removed," and it auto-disabled the connector for every affected account. Re-enabling them required each customer to manually reauthorize — weeks of support tickets for a rename that needed one alias line to be safe.
