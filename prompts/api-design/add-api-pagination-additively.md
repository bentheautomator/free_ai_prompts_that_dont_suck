---
title: Add API Pagination Additively
slug: add-api-pagination-additively
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops bolting pagination onto an endpoint and silently truncating old clients"
---

# Add API Pagination Additively

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding pagination to an endpoint that returned everything, silently capping existing clients at the first page.

**[Copy-paste ready version](../../install/add-api-pagination-additively.md)** — just the instruction block, no explanation.

## The Problem

"This endpoint returns the whole table — add pagination" is a reasonable request with a default implementation that quietly corrupts data downstream. The AI adds `page` and `per_page` params, sets `per_page` to default to 50, and often wraps the response in `{"data": [...], "meta": {...}}` while it's in there. New clients are happy. Old clients — the ones that send no pagination params because pagination didn't exist when they were written — now receive the first 50 records and no error.

That's the cruelest failure shape in API design: not a crash, but a silently truncated dataset. A nightly sync job pulls 50 of 12,000 customers and "succeeds." A reporting pipeline computes totals over one page. An admin export looks complete to anyone who doesn't count rows. Nothing alerts, because every response is a 200 with valid JSON.

The AI builds it this way because every pagination tutorial and framework helper paginates by default with a sane page size. The pattern is correct for a new endpoint. Applied to a shipped endpoint, the "sane default" is the breaking change.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Add API Pagination Additively

When adding pagination to an existing endpoint, the default behavior for requests WITHOUT pagination parameters MUST remain "return everything," exactly as before. A default page size silently truncates every existing client to page one — a 200 response with most of the data missing and no error.

- Paginate only when the caller opts in (sends `page`, `limit`, `cursor`, or similar). No params means the full, unwrapped, original response.
- Do not change the response shape for legacy requests. If paginated responses gain an envelope (`{"data": [], "meta": {}}`), only opted-in requests get it; param-less requests keep the bare array.
- Do not impose a max page size that's smaller than the current full result, and do not let framework pagination helpers apply their default limits to param-less requests.
- Silent truncation is worse than slowness. If the unpaginated query is the performance problem, say so and let the user choose between a versioned endpoint, a deprecation window with client outreach, or accepting the cost temporarily.
- The same applies in reverse contexts: never lower an existing default page size or maximum limit — clients sized their loops to the current values.

**Red flags that you're about to violate this:**
- "Defaulting to 50 per page is standard; clients can pass a higher limit if they want."
- "Returning the entire table was always a bug — I'm fixing it."
- "The framework paginator handles missing params with a sensible default."
- "Existing callers will still get a 200, so this is backward compatible."
- "Anyone consuming this much data should have been paginating already."

---

## Why It Works

1. **It names silent truncation as the failure**, which the AI otherwise doesn't register — its compatibility check is "do old requests still return 200?", and they do.
2. **It defines opt-in as the compatibility line**: params present means new behavior, params absent means old behavior. That's mechanical enough to survive any framework's defaults.
3. **It couples shape and size**, catching the secondary break where the pagination envelope changes the response structure for clients that never asked for pages.
4. **It ranks slowness above truncation explicitly**, countering the AI's performance instinct, which otherwise treats the unbounded query as the bug and the cap as the fix.

## Origin

An assistant was asked to paginate a `/products` endpoint that had grown to return 30,000 items. It added cursor pagination with a default page of 100 — clean implementation, good tests. A reseller's nightly catalog sync, which sent no parameters, began importing exactly 100 products and deactivating the other 29,900 as "removed from feed." The reseller's storefront emptied out over a weekend, and the bug was hard to find precisely because both sides logged nothing but successes.
