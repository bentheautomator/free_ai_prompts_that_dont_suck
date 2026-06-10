---
title: Ack Webhooks Fast, Do Work Async
slug: ack-webhooks-fast-do-work-async
category: backend
tags: [universal, backend, webhooks]
works_with: all
severity: high
one_liner: "Stops slow inline webhook processing from triggering redelivery storms"
---

# Ack Webhooks Fast, Do Work Async

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents webhook handlers that do heavy work before responding, time out the provider, and get the same event redelivered into an already-struggling service.

**[Copy-paste ready version](../../install/ack-webhooks-fast-do-work-async.md)** — just the instruction block, no explanation.

## The Problem

Webhook providers give you a small, hard response budget — commonly 5 to 30 seconds — and treat anything slower as a failed delivery, which they retry. AI assistants write webhook handlers as if that budget didn't exist: receive the event, then synchronously update three tables, call two downstream APIs, regenerate a PDF, send an email, and finally return 200. In dev each step takes milliseconds and the handler responds instantly.

In production, one slow downstream call pushes the handler past the provider's timeout. The provider marks the delivery failed and redelivers — into a service that's slow precisely because it's busy doing inline webhook work. Now the same expensive pipeline runs again, concurrently, for the same event. Load doubles, more deliveries time out, more redeliveries arrive. Past a threshold of consecutive failures, many providers disable the endpoint entirely, and you stop receiving events at all until someone notices and re-enables it.

The contract a webhook endpoint actually has is "durably accept this notification quickly," not "finish all resulting business logic before answering." Assistants conflate the two because in a single-request test they're indistinguishable.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Ack Webhooks Fast, Do Work Async

A webhook handler's job is to durably accept the event and return 2xx within a couple of seconds. NEVER run slow or multi-step business logic inline before responding to a webhook: providers time out slow responses, count them as failures, redeliver into your now-busy service, and eventually disable the endpoint.

- In the handler do only: verify the request, persist the event (insert into a table or publish to a queue), return 200. Everything else happens in a worker that consumes what you persisted.
- The persistence step must be durable before you respond. Acking and then doing the work from memory means a crash after the 200 silently loses the event, and the provider will never resend it — you told it delivery succeeded.
- No outbound API calls, email sends, file generation, or fan-out inside the handler. One slow third party in that path becomes your timeout.
- Status codes signal delivery, not business outcome. If the event is stored, return 200 even though processing hasn't happened yet; report processing failures through your own job retries and alerts, not the webhook response.
- Keep the synchronous path's only failure modes to "could not verify" and "could not persist" — those are the cases where you genuinely want the provider to retry.
- If the work is truly trivial (set one flag, one indexed update), inline is fine. The moment there's a second side effect or any network call, move it behind the queue.

**Red flags that you're about to violate this:**
- "The processing only takes a second or two, well within the timeout."
- "Adding a queue for this one webhook is over-engineering."
- "I'll do the work first so I can return an accurate status code."
- "The provider's timeout is 30 seconds, we have plenty of room."
- "If processing fails, returning 500 gets us a free retry from the provider."
- "I'll respond 200 immediately and then keep processing in this request."

---

## Why It Works

1. **It redefines what the 200 means.** Assistants want the response code to report the business outcome, which forces the work inline. Stating that webhook status codes signal *delivery* dissolves the reason for the slow path.
2. **It names the feedback loop.** "Slow handler → timeout → redelivery → slower handler" is invisible in single-request testing. Spelling it out makes the cost of inline work concrete rather than theoretical.
3. **It closes the ack-then-work-in-memory shortcut.** The lazy version of "respond fast" is returning 200 and continuing in the same request context, which loses events on crash with no retry coming. Requiring durable persistence *before* the response is the load-bearing detail.
4. **It blocks the "free retry via 500" trick.** Using provider redelivery as your job retry system couples your error handling to their retry schedule and marches the endpoint toward auto-disable.

## Origin

An order-management integration processed a marketplace's `order.created` webhooks inline: inventory update, shipping-label API call, confirmation email. The label vendor had a slow afternoon, handler latency crossed the marketplace's 10-second limit, and redeliveries piled onto the struggling service until the marketplace auto-disabled the endpoint for repeated failures. Orders silently stopped arriving for six hours; the backfill and the duplicate-label cleanup took two days. The rewrite stored the event and returned 200 in under 50 milliseconds.
