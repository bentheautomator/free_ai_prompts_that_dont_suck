---
title: Rate-Limit Login, OTP, and Reset Endpoints
slug: rate-limit-auth-endpoints
category: security
tags: [universal, security, auth]
works_with: all
severity: high
one_liner: "AI shipping login and OTP endpoints with unlimited guessing allowed"
---

# Rate-Limit Login, OTP, and Reset Endpoints

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI-built auth flows that allow unlimited password, OTP, and token guessing.

**[Copy-paste ready version](../../install/rate-limit-auth-endpoints.md)** — just the instruction block, no explanation.

## The Problem

An AI builds a login endpoint that correctly hashes passwords, correctly compares them, correctly returns a generic error — and answers as many guesses per second as the attacker's connection can carry. Same for the 6-digit SMS code (a million possibilities, brute-forceable in hours at modest request rates), the password-reset flow (free username enumeration plus token guessing), and the "verify card" endpoint that lets someone iterate CVVs. Throttling is invisible in the feature spec, absent from the happy path, and missing from most tutorial code, so the model simply doesn't build it; credential stuffing and OTP brute force are then not vulnerabilities in any single line — the vulnerability is a sum the codebase never computes.

The companion failure is subtractive: a rate limit exists and the AI removes or widens it because it broke something. Load tests trip it, the E2E suite logs in 500 times, a shared office IP hits the threshold — and the fix becomes `max: 100000`, an env-gated bypass that leaks to prod, or deleting the middleware "since it's causing flakiness." Both failures end the same way: an endpoint where guessing is free.

The needed posture is small and standard: per-account and per-IP counters on auth-shaped endpoints, lockout/backoff on the things with tiny keyspaces, and limits that tests work around rather than remove.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rate-Limit Login, OTP, and Reset Endpoints

ALWAYS apply rate limiting and attempt caps when building authentication-adjacent endpoints, and NEVER remove or hollow out an existing limit to fix tests or load complaints.

An unthrottled login is a password oracle; an unthrottled 6-digit OTP check is a solvable puzzle, not a control.

- Endpoints that need limits by default: login, OTP/2FA verification, password reset request and reset-token submission, email verification, signup (abuse), API key validation, and anything comparing a short code. Build the limit with the endpoint, not as a hardening backlog item.
- Limit on two axes: per-target-account (stops distributed guessing against one user) and per-IP (stops one source spraying many accounts). IP-only misses botnets; account-only enables lockout-as-harassment — use both, with the account axis escalating to delays or step-up (CAPTCHA) rather than hard permanent lockout.
- Tiny keyspaces get hard caps: OTP and SMS codes allow 5-10 attempts, then invalidate the code and issue a new one. Reset tokens: long, random, single-use, expiring — and still capped.
- Use real infrastructure: the framework's limiter or a Redis-backed counter. An in-memory `Map` in one process limits nothing behind a load balancer; note this when you see it.
- When a limit blocks tests or load runs, the fix is test-shaped: dedicated test hooks, limiter exemptions for specific test credentials in non-prod config, or resetting counters between runs. Never raise the global threshold to "basically off," delete the middleware, or add an `X-Skip-RateLimit` style header check that ships to production.
- Respond to limited requests with 429 and no oracle: the response must not reveal whether the password would have been correct, or whether the account exists.

**Red flags that you're about to violate this:**
- "Rate limiting is an optimization, the auth logic is what matters for now..."
- "The E2E suite keeps tripping the limiter, I'll bump the max way up..."
- "Per-IP limiting covers it, attackers come from one place..."
- "Six digits plus a 10-minute expiry is too short a window to brute force..."
- "I'll add a bypass header so QA stops complaining..."
- "The in-memory limiter works in dev, distributed counters are over-engineering..."

---

## Why It Works

1. **It moves throttling into the endpoint's definition of done.** The omission happens because limits aren't in the feature's visible requirements; making them part of "auth endpoint" closes the gap where the vulnerability lives.

2. **It mandates both axes with the reason each exists.** AIs that do add limiting pick one axis (usually IP) and consider it handled; naming the botnet and lockout-harassment failure modes explains why the pair is the unit.

3. **It pre-writes the test-friction resolution.** Limits die when they annoy CI; providing the legitimate workarounds (exempt test creds, counter resets) means the AI fixes the test instead of disabling the control.

4. **It does the OTP math.** "A million combinations" sounds like a lot until it's framed as hours of requests; the 5-to-10-attempts-then-reissue rule replaces intuition with a number.

## Origin

A fintech's SMS login flow, generated in one productive afternoon, checked 6-digit codes with no attempt counter; the codes lived for ten minutes. A researcher demonstrated account takeover by spraying the keyspace from a handful of IPs well inside the window, then found the load-test config had also raised the gateway's generic rate limit to a million requests per hour "temporarily." Two missing counters — per-code attempts and per-account velocity — would each independently have stopped it.
