---
title: No Side Effects in API GET Endpoints
slug: no-side-effects-in-api-get
category: api-design
tags: [universal, apis, rest]
works_with: all
severity: high
one_liner: "Stops state-changing GET endpoints that prefetchers and scanners auto-trigger"
---

# No Side Effects in API GET Endpoints

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from putting state changes behind GET, where caches, prefetchers, retries, and crawlers will trigger them without anyone clicking anything.

**[Copy-paste ready version](../../install/no-side-effects-in-api-get.md)** — just the instruction block, no explanation.

## The Problem

Asked for a quick way to approve a request, confirm an email, or reset a counter, AI assistants regularly reach for `GET /approve?id=123` — especially when the trigger is "a link in an email" or "something easy to test in the browser." It works in the demo. Then the infrastructure that's allowed to assume GET is safe starts doing its job: an email client's link scanner pre-fetches the URL and approves the request before the human opens the message. A browser prefetches the link on hover. A proxy retries the request after a timeout, performing the action twice. A monitoring health-check or crawler walks the route and fires it on a schedule.

None of these are bugs in those tools. HTTP's contract says GET is safe and idempotent, and an entire ecosystem — caches, prefetchers, retry layers, security scanners — is built on taking that promise literally. A mutating GET isn't unconventional; it's a landmine placed where the ecosystem is contractually allowed to step.

The AI does it because GET is the lowest-friction verb: no body, clickable, curl-able, embeddable in an email. The machinery that will abuse that convenience is invisible at code-writing time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Side Effects in API GET Endpoints

NEVER implement an endpoint that creates, modifies, or deletes state behind GET (or HEAD). The HTTP contract marks GET as safe, and real infrastructure acts on that promise: email link scanners pre-fetch URLs, browsers prefetch on hover, proxies retry freely, and crawlers walk every route. A mutating GET will be triggered by machines, repeatedly, with no human intent.

- State changes go behind POST, PUT, PATCH, or DELETE. This includes the deceptively read-like ones: marking notifications read, recording views or analytics on the server, "tracking" opens, logging someone out, regenerating a token, advancing a workflow.
- Email-link actions (confirm, approve, unsubscribe) must not mutate on the GET itself: serve a page whose button issues the POST, or follow the established one-click pattern where the mutation rides a POST. Link scanners *will* fetch the URL before the user does.
- Do not bend the rule for convenience ("easier to test in a browser"), for webhook receivers (receiving data is a POST), or for "harmless" mutations — retried and prefetched harmless mutations stop being harmless.
- If you find an existing mutating GET, do not silently convert it to POST either — existing callers use GET. Add the POST route, keep the GET temporarily as deprecated, and flag the migration to the user.
- Reads with incidental non-observable bookkeeping (cache warming, last-accessed metrics) are acceptable; anything a user or another system can observe as changed is not.

**Red flags that you're about to violate this:**
- "It's just a confirmation link — a GET is the simplest thing that works."
- "This makes it easy to test by pasting the URL in a browser."
- "Marking it as read is barely a mutation."
- "No crawler will ever find an internal admin route."
- "I'll add the side effect to the existing GET so we don't need a new endpoint."

---

## Why It Works

1. **It replaces an abstract rule with concrete attackers.** "GET should be safe" is a convention the AI will trade away for convenience; "email scanners will click this before the human does" is a mechanism it can't argue with.
2. **It enumerates the read-like mutations** (mark-as-read, logout, token regeneration) that slip past a naive definition of side effect.
3. **It pre-solves the email-link case**, the single scenario where the AI most often decides the rule can't apply — showing the compatible pattern removes the excuse.
4. **It blocks the overcorrection**, where the AI "fixes" a legacy mutating GET by breaking its existing callers, by prescribing the additive migration instead.

## Origin

An assistant built an expense-approval flow with `GET /approvals/{id}/accept` links emailed to managers. The company's email security gateway fetched every link in every message to scan for phishing — approving every expense report, instantly, including ones the managers never opened. Finance noticed only when an intentionally-rejected test expense came back approved. The fix was a confirmation page with a POST button; the audit of three weeks of auto-approved expenses took rather longer.
