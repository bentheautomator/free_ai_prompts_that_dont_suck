---
title: Match Existing API Naming Conventions
slug: match-existing-api-naming-conventions
category: api-design
tags: [universal, apis]
works_with: all
severity: medium
one_liner: "Stops new endpoints that ignore the API's established naming conventions"
---

# Match Existing API Naming Conventions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding new endpoints and fields in its own preferred style instead of the conventions the API already uses.

**[Copy-paste ready version](../../install/match-existing-api-naming-conventions.md)** — just the instruction block, no explanation.

## The Problem

There are two ways to make an API inconsistent, and this repo's other prompts cover the destructive one (renaming what shipped). This is the other: the AI adds a *new* endpoint in its house style rather than yours. The existing API says `/users/{id}/orders`, plural resources, snake_case fields, `?page=` pagination. The new endpoint arrives as `/getInvoiceList`, camelCase fields, `?pageNumber=` — textbook-correct in some textbook, alien in this API. Or the inverse: your API is consistently camelCase RPC-style, and the AI delivers an immaculately RESTful, snake_cased addition because that's what its training distribution prefers.

No consumer breaks today, which is why this is the category's misdemeanor rather than its felony. The cost arrives on a delay: every consumer now needs two mental models and two serializer configs; client codegen produces mixed-style models; and the next developer (or next AI session) can't tell which convention is canonical, so the drift compounds. Worst, the inconsistency eventually tempts someone to "clean it up" — and *that* cleanup is the breaking change every other prompt in this category exists to stop. Convention drift is how future breakage gets manufactured.

The AI does this because, absent instructions, it defaults to the most common patterns in its training data — not the patterns three feet away in your route file. It optimizes for "good API design" in the abstract when the only correct style is the incumbent one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match Existing API Naming Conventions

When adding new endpoints, fields, or parameters to an existing API, ALWAYS follow the conventions the API already uses — even where they differ from REST best practices or your preferred style. The incumbent convention is correct by definition; an objectively nicer style that's inconsistent makes the API worse and manufactures pressure for a future breaking "cleanup."

- Before designing anything new, read the existing surface: route files, OpenAPI/schema definitions, or a handful of existing handlers. Extract the live conventions for: path style (plural/singular, nesting depth, kebab/camel segments), field casing (snake_case vs camelCase), parameter names (`page`/`per_page` vs `offset`/`limit` vs `cursor`), ID field naming (`id` vs `user_id` vs `uuid`), timestamp field naming and format, envelope shape, and error body shape.
- Copy those conventions exactly. If the API is RPC-style (`/getUserOrders`), new endpoints are RPC-style. If it paginates with `?page=`, the new list endpoint paginates with `?page=` — not the cursor scheme you'd choose green-field.
- When the existing API is itself inconsistent, match the dominant or most recent pattern, and say which one you followed and why in your summary.
- Do not "fix" existing names to match the new endpoint, and do not introduce a better convention as a beachhead ("new endpoints will use the new style going forward") unless the user explicitly establishes that policy.
- If the incumbent convention is genuinely problematic (e.g., it collides with a framework constraint), raise it as a question before building, rather than unilaterally deviating.

**Red flags that you're about to violate this:**
- "I'll use REST conventions for the new endpoint even though the API is RPC-style."
- "camelCase is the JSON standard, whatever the older fields do."
- "This is a fresh endpoint, so it's a chance to start doing things right."
- "Cursor pagination is better, and only the new endpoint will have it."
- "I didn't check the other routes — list endpoints are pretty standard anyway."

---

## Why It Works

1. **It defines the incumbent style as correct by definition**, dissolving the abstract-quality comparison the AI otherwise runs (its trained preferences vs. your file) in favor of a lookup.
2. **It mandates reading before designing**, converting convention-matching from an intention into a concrete step with named things to extract.
3. **It blocks the beachhead maneuver** — "new style for new endpoints" — which is how single-endpoint drift becomes a permanently two-styled API without anyone deciding that.
4. **It connects drift to future breakage**: inconsistency invites the cleanup rename that breaks consumers, so the misdemeanor is named as the felony's accomplice.

## Origin

A team's API used snake_case fields and `?page=` pagination across thirty endpoints. Over a month of AI-assisted feature work, four new endpoints landed with camelCase fields and `?cursor=` — each individually fine, collectively a second dialect. The partner-facing client library now needed per-endpoint serializer overrides, and a new hire's "quick consistency pass" PR — which would have broken all thirty original endpoints — got as far as code review before anyone realized the real fix was a one-line instruction telling the assistant to match the house style.
