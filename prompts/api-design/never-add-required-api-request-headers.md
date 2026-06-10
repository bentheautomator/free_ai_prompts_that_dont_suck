---
title: Never Add Required API Request Headers
slug: never-add-required-api-request-headers
category: api-design
tags: [universal, apis, compatibility]
works_with: all
severity: high
one_liner: "Stops new mandatory headers that reject every existing caller at once"
---

# Never Add Required API Request Headers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from making a new or existing request header mandatory on shipped endpoints, instantly rejecting every caller that predates it.

**[Copy-paste ready version](../../install/never-add-required-api-request-headers.md)** — just the instruction block, no explanation.

## The Problem

Headers are where AI assistants put cross-cutting requirements, and requirements have a way of becoming mandatory. Building a client-version gate, the AI requires `X-Client-Version` on every request and rejects its absence. Adding idempotency support, it makes `Idempotency-Key` required on POSTs. Introducing request tracing, multi-tenancy, or API versioning, it starts demanding `X-Request-ID`, `X-Tenant-ID`, or `X-API-Version` — usually in a middleware, which means *every endpoint at once*. Sometimes it just tightens `Content-Type` checking, and callers who always sent `text/plain` bodies that parsed fine as JSON get 415s.

The arithmetic is unforgiving: a header introduced today is sent by zero existing callers. Making it required is therefore a 100% rejection rate for the installed base — not an edge case, the *entire* base — and because it ships in middleware, the blast radius is the whole API, not the endpoint under work. Old mobile builds, partner servers, cron scripts: none of them can start sending a header retroactively.

The AI does it because requiring the header is the simplest correct-looking enforcement of whatever feature it's building, and the feature's logic ("we can't trace requests without an ID") sounds like it justifies rejection. It doesn't. It justifies a default.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Add Required API Request Headers

NEVER make a request header mandatory on an existing endpoint — neither a new header nor stricter enforcement of an existing one. A header introduced today is, by definition, sent by zero existing callers; requiring it rejects the entire installed base in one deploy, and middleware-level enforcement does it across every endpoint simultaneously.

- New headers (`X-Request-ID`, `X-Client-Version`, `X-Tenant-ID`, `Idempotency-Key`, custom auth-adjacent metadata) must be optional with a server-side default: generate the request ID, infer the tenant from the existing auth context, treat absent idempotency keys as non-idempotent requests — exactly as the endpoint behaved before.
- Do not tighten existing header handling on shipped endpoints: stricter `Content-Type` matching, newly-enforced `Accept` negotiation, or `User-Agent` requirements all reject callers whose requests worked yesterday.
- Middleware multiplies the mistake. A required-header check added globally converts one feature's requirement into an API-wide breaking change. Scope any enforcement to new endpoints only.
- The legitimate path to a required header: accept-and-log absence first, measure which callers omit it, notify them, and enforce on a deadline by human decision — or require it only in the next API version.
- If the user explicitly asks to require a header, state the consequence precisely — every existing caller fails immediately with 4xx — and propose the optional-with-default or log-then-enforce path.

**Red flags that you're about to violate this:**
- "The tracing system needs a request ID, so requests without one are invalid."
- "Requiring the client version header lets us handle old clients properly."
- "Strict Content-Type checking is just correct HTTP."
- "I'll enforce it in middleware so no endpoint can forget it."
- "It's one header — clients can add it in a minute."

---

## Why It Works

1. **It states the zero-sender arithmetic.** "New header" and "required" sound independently reasonable; pointing out that their combination rejects 100% of existing traffic makes the contradiction unmissable.
2. **It converts each requirement into its default** (generate the ID, infer the tenant), demonstrating that the feature never actually needed rejection — the AI conflates "needs the value" with "needs the caller to send it."
3. **It flags middleware as a blast-radius multiplier**, since the AI's instinct to enforce centrally is precisely what turns a local mistake into an API-wide outage.
4. **It pre-rebuts "clients can add it in a minute"** by the nature of installed bases: shipped binaries and partner servers don't take updates on your deploy schedule.

## Origin

Implementing request tracing, an assistant added middleware requiring `X-Correlation-ID` and returning 400 without it — clean code, nice error message, applied globally. The staging environment, where all clients were the team's own updated tools, looked perfect. In production, every partner API call and every pre-update mobile session failed at midnight deploy. Total rejection lasted eleven minutes before rollback; the correct version — generate the ID when absent — was a three-line change that shipped the next morning.
