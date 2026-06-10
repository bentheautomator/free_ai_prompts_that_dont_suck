---
title: Never Put Tokens or Keys in URL Query Strings
slug: no-tokens-in-query-strings
category: security
tags: [universal, security, secrets]
works_with: all
severity: high
one_liner: "AI passing api_key and session tokens as URL parameters"
---

# Never Put Tokens or Keys in URL Query Strings

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from designing APIs and links that carry credentials in URLs, where every log and referrer sees them.

**[Copy-paste ready version](../../install/no-tokens-in-query-strings.md)** — just the instruction block, no explanation.

## The Problem

`GET /api/data?api_key=sk_live_abc123`. It's the easiest possible authentication to implement and test — paste the URL in a browser, it works — which is exactly why AI assistants design it, and why they "simplify" SDK examples into it, and why they put session tokens in links ("click here to view your document?token=..."). URLs, though, are the most-copied strings in computing: they land in server access logs by default, in proxy and load-balancer logs, in CDN logs, in browser history synced across devices, in `Referer` headers sent to every third-party resource the destination page loads, in analytics tools that record page URLs, in screenshots, and in chat messages when someone shares "the link."

A credential in a URL is therefore a credential duplicated into a dozen systems with different owners, none of which treat their contents as secret. The variants the AI produces: API keys as query params (instead of `Authorization` headers), JWTs in redirect URLs during half-remembered OAuth implementations (the implicit flow's fragment tokens, resurrected as query params), password-reset and magic-login links with no expiry or reuse limit (these must be in URLs — the discipline is making them short-lived and single-use), and signed URLs minted with year-long lifetimes "so they don't break."

Headers, cookies, and POST bodies exist precisely because they don't appear in logs and referrers.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Put Tokens or Keys in URL Query Strings

NEVER carry long-lived credentials in URLs. API keys go in the `Authorization` header; session state goes in cookies or headers; one-time links get short expiry and single-use enforcement.

URLs are copied everywhere by default: access logs, proxy logs, Referer headers, browser history, analytics. A key in a query string is a key distributed to every system that ever sees the request line.

- API authentication: `Authorization: Bearer <token>` (or the provider's header). Do not design `?api_key=` parameters into new endpoints, and do not use a provider's legacy query-param auth when a header form exists. Examples and docs you write follow the same rule.
- Never place session tokens, JWTs, or OAuth access tokens in query strings or in redirect URL parameters. For browser flows, use the authorization-code flow where tokens move in POST bodies and cookies, not the URL bar.
- Links that must carry a secret (password reset, magic login): single-use tokens, expiring in minutes-to-hours, invalidated on use and on password change, with the landing page immediately exchanging the token for a session and scrubbing it from the address bar.
- Mint presigned URLs (S3-style) with the shortest workable expiry, scoped to one object and method; an unexpiring signed URL is a permanent public link in disguise.
- Defense in depth for pages that ever see sensitive URLs: `Referrer-Policy: strict-origin-when-cross-origin` or stricter, and configure logging/telemetry to redact known token parameters.
- GET-with-body-in-query designs ("?password=" on a login form because GET was easier) are the same bug with less dignity; credentials ride in POST bodies.

**Red flags that you're about to violate this:**
- "Query-param auth means users can test the API right in the browser..."
- "The link token is random and unguessable, the URL is as good as private..."
- "Our logs are internal, who cares if the key appears there..."
- "I'll give the presigned URL a one-year expiry so customer links never break..."
- "The provider's docs show api_key as a parameter, I'll match their example..."
- "It's HTTPS, the URL is encrypted anyway..."

---

## Why It Works

1. **It enumerates where URLs actually go.** "Don't put secrets in URLs" without the log/referrer/history list reads as style preference; the distribution list is what makes the duplication threat concrete enough to outweigh browser-testability.

2. **It kills the HTTPS rationalization.** TLS protects the URL in transit and nowhere else — both endpoints log the full request line; one sentence separates transport encryption from storage exposure.

3. **It handles the must-be-a-URL cases with discipline instead of denial.** Reset and magic links can't use headers; giving the single-use/short-expiry/exchange-and-scrub recipe keeps the rule realistic where the naive version would be ignored.

4. **It covers authoring, not just implementing.** AIs reproduce query-param auth from provider examples into docs and SDK snippets, propagating the pattern; including examples in scope stops the spread at the source.

## Origin

A data API authenticated via `?api_key=` because the original assistant-built prototype did, and the pattern fossilized into the public docs. Keys then surfaced exactly as the textbooks predict: in a CDN provider's request logs reviewed during an unrelated incident, in customers' browser histories on shared machines, and in Referer headers sent to a third-party script on the API's own status page. The migration to header auth took a sprint; revoking and reissuing every customer key took a quarter.
