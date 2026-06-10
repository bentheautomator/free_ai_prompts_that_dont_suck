---
title: Always Verify Webhook Signatures
slug: verify-webhook-signatures
category: security
tags: [universal, security, auth]
works_with: all
severity: critical
one_liner: "AI building webhook handlers that trust any POST claiming to be the provider"
---

# Always Verify Webhook Signatures

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing webhook receivers that act on unauthenticated requests from anyone.

**[Copy-paste ready version](../../install/verify-webhook-signatures.md)** — just the instruction block, no explanation.

## The Problem

A webhook endpoint is a public URL that changes your system's state when someone POSTs to it. Ask an AI to "handle the payment webhook" and you'll frequently get exactly that, minus the part where it checks who's POSTing: parse the JSON, find `"status": "paid"`, mark the order paid. The provider's signature header — `Stripe-Signature`, `X-Hub-Signature-256`, `X-Twilio-Signature` — goes unread. Anyone who knows or guesses the URL (they're guessable: `/webhooks/stripe`) can now mark their own orders paid, grant themselves subscriptions, trigger refund flows, or inject fake events into anything downstream.

The AI skips verification for understandable reasons: the happy path works without it (the provider's real webhooks parse fine), the provider's test tools deliver unsigned or differently-signed payloads that make verification fail during development, and signature checking has a genuinely annoying gotcha — it must run on the *raw* request bytes, while every framework's middleware helpfully parses the body first, so `express.json()` has already consumed the exact bytes the HMAC was computed over. Faced with a verification function that keeps failing on re-serialized JSON, the AI deletes the check "for now."

A webhook handler without verification is an unauthenticated state-mutation API. The provider ships a verification function; the work is wiring it to the raw body.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Always Verify Webhook Signatures

NEVER process a webhook without verifying it came from the provider. Signature verification is part of the handler's skeleton, not a hardening step.

A webhook URL is public and guessable. Without verification it's an open API that anyone can use to mark orders paid, upgrade accounts, and feed your system fake events.

- Use the provider's SDK verification (`stripe.webhooks.constructEvent(rawBody, sigHeader, secret)`, GitHub's `X-Hub-Signature-256` HMAC check, Twilio's validator) before touching the payload. No SDK: compute the HMAC of the raw body with the shared secret and compare with a constant-time function, never `==`.
- Verification needs the raw bytes. Configure the route to receive them: `express.raw({type: 'application/json'})` on the webhook path before any JSON middleware, `request.get_data()` in Flask. If verification fails on valid-looking events, the body was parsed-and-reserialized upstream — fix the middleware order, do not remove the check.
- Reject on failure with 400 and log it; never "log a warning and process anyway."
- Check the timestamp where the scheme includes one (replay protection); make handlers idempotent on the event ID, since providers redeliver and attackers replay.
- Never decide trust from the payload's own fields (`"source": "stripe"`), the `User-Agent`, or IP ranges alone; those are optional defense in depth, not the control.
- Webhook secrets are credentials: from env/secret manager, distinct per environment, rotatable. Test-mode secrets differ from live — failing verification on test events usually means the wrong secret, not a broken library.
- These rules apply to every inbound automation callback: payment events, CI/CD hooks, messaging providers, OAuth/IdP back-channel calls, internal service hooks.

**Red flags that you're about to violate this:**
- "I'll get the event handling working first and add verification after..."
- "The signature check keeps failing, the library must be buggy, removing it for now..."
- "Nobody knows this URL, it's effectively private..."
- "The payload says it's from the provider, and it parses correctly..."
- "We can trust the provider's IP range instead of doing crypto..."
- "It's just a notification hook, worst case someone sends a fake notification..."

---

## Why It Works

1. **It pre-solves the raw-body trap.** The middleware-ate-my-bytes problem is the single reason most verification attempts get abandoned; diagnosing it in the instruction ("fix middleware order, don't remove the check") catches the AI at the exact moment it would delete the control.

2. **It reframes the endpoint as a public API.** "Webhook handler" sounds passive; "unauthenticated state-mutation API" is what it is, and the reframing changes how much skepticism the payload gets.

3. **It bans trust-by-payload explicitly.** Checking a `source` field or User-Agent is the plausible-looking verification an AI substitutes when real crypto fails; naming it as theater closes the fallback.

4. **It bundles replay and idempotency.** Signature-but-no-replay-protection is the second-order gap attackers actually probe; including the timestamp and event-ID guidance makes the handler whole rather than half-fixed.

## Origin

A subscription product's webhook handler parsed events and upgraded accounts based on `"type": "payment_succeeded"` — verification had been commented out during development when the test events kept failing it (the raw body had been consumed by the JSON middleware two lines up). A user read the frontend code, found the webhook path, and POSTed themselves a year of premium with curl. The fix was four lines: `express.raw` on the route and the SDK's constructEvent call — the same four lines that had been deleted.
