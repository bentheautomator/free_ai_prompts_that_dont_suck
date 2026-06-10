---
title: Don't Let Error Handlers Throw
slug: dont-let-error-handlers-throw
category: error-handling
tags: [universal, errors, exceptions]
works_with: all
severity: medium
one_liner: "AI catch blocks that crash on optional error fields, hiding the real failure"
---

# Don't Let Error Handlers Throw

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the catch block itself from crashing and replacing the real error with a sideshow.

**[Copy-paste ready version](../../install/dont-let-error-handlers-throw.md)** — just the instruction block, no explanation.

## The Problem

A request fails and control lands in the handler: `except RequestException as e: logger.error(f"API error {e.response.status_code}: {e.response.json()['message']}")`. Looks diligent. But when the failure is a connection timeout, `e.response` is `None` — and the handler dies with `AttributeError: 'NoneType' object has no attribute 'status_code'`, raised from inside the except block. The error that gets reported is the handler's own faceplant; the timeout that actually happened is reduced to a `__during handling of the above exception__` footnote, or in JavaScript, simply replaced.

AI assistants write handlers against the *richest* version of the error — the HTTP failure with a populated response, the exception with structured fields, the JSON error body with a `message` key — because that's the version that makes for an informative log line. But error objects are precisely where optionality lives: `e.response` may be None, the body may not be JSON, `error.code` may be undefined, the third-party SDK's exception may not have the attribute this version of the docs promised. Handler code runs rarely, on the weirdest inputs the system produces, and gets approximately zero test coverage. Optimistic field access there fails at the worst moment available: mid-incident, while masking the evidence.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Let Error Handlers Throw

Code inside a catch/except block must be written defensively — it runs at the worst possible moment, against the least predictable inputs, and if it throws, it destroys the very error it was supposed to report.

- Never chain optional fields optimistically in a handler: `e.response.status_code` crashes when `response` is None (true for timeouts/connection errors in most HTTP libraries); write `status = e.response.status_code if e.response is not None else "no response"`
- Don't assume error payloads parse: `e.response.json()["message"]` assumes a body, valid JSON, and a `message` key — three assumptions about a *failure*; fall back to raw text, truncated: `body = e.response.text[:500] if e.response else ""`
- In JavaScript, `catch (e)` receives anything — not necessarily an Error: check before using (`e instanceof Error ? e.stack : String(e)`); accessing `e.response.data.message` off an unknown deserves optional chaining and a fallback
- Keep handlers short and dumb: log the exception object itself with the language's built-in formatting (`logger.error("request failed", exc_info=True)`, `logger.error(err)`) rather than hand-assembling messages from its internals — the built-in path doesn't crash on missing fields
- Anything nontrivial a handler does (cleanup calls, notification sends, metrics) can itself fail; if the handler must do real work, guard that work so the original exception still gets reported and re-raised first or regardless
- Test the handler with the *poorest* error available (timeout with no response, non-JSON body), not just the rich one

**Red flags that you're about to violate this:**
- "The error will have a response object with the details..."
- "I'll pull message out of the error body for a nicer log line..."
- "Status code is always there on a failed request..."
- "The catch just formats and logs; nothing to go wrong..."
- "The SDK's exceptions all have a .code attribute..."

---

## Why It Works

1. **It inverts the input model for handlers.** The model writes catch blocks against the best-documented error shape; declaring handler inputs the *least* predictable in the program — and naming the None-response timeout as the canonical example — recalibrates what the handler must survive.

2. **It steers toward crash-proof primitives.** `exc_info=True` and logging the error object directly cannot fail on missing fields; making the built-in path the default removes the hand-assembled f-string where the second crash lives.

3. **It counts the assumptions.** "Body exists, is JSON, has `message`" — three independent bets inside one expression, placed on a failure case — makes the optimism quantifiable and therefore visible.

4. **It exposes the coverage hole.** Handler code's combination of rare execution and zero tests is *why* this bug survives to production; stating it justifies the defensive style the model would otherwise consider paranoid.

## Origin

A service integrated a vendor API with AI-written error handling that extracted `err.response.data.error.message` for every failure. During a vendor outage — the exact event the handling existed for — the vendor's load balancer returned HTML error pages, `data.error` was undefined, and every catch block in the integration threw `TypeError: Cannot read properties of undefined`. On-call spent the first forty minutes debugging their own error handler before discovering the vendor was down, an outage the untouched error object had been announcing the entire time.
