---
title: Reuse Expensive Clients and Connections
slug: reuse-expensive-clients-and-connections
category: performance
tags: [universal, performance, network]
works_with: all
severity: high
one_liner: "Stops creating new HTTP clients and DB connections on every call"
---

# Reuse Expensive Clients and Connections

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from constructing a fresh HTTP client, database connection, or SDK instance per request when one long-lived, reusable instance is the intended design.

**[Copy-paste ready version](../../install/reuse-expensive-clients-and-connections.md)** — just the instruction block, no explanation.

## The Problem

`def handler(): conn = psycopg2.connect(...)`. A `new S3Client()` inside the function that uploads one file, called per request. `requests.get()` in a loop, which silently builds a fresh connection (TCP handshake, TLS negotiation, no keep-alive) for every single call when a `Session` would reuse one. Each construction looks like a single line; each hides real work — DNS resolution, TCP and TLS handshakes, auth flows, connection-pool setup, sometimes credential fetches against a metadata service. Done once at startup, that work is free. Done per request at scale, it can dominate the request itself: a 5ms query behind a 60ms connect is a service that's 92% overhead.

AI assistants write per-call construction because it's maximally self-contained — the function needs a client, so the function makes a client. Every SDK's quickstart does exactly this, because quickstarts run once. The pattern is also state-free, which feels clean. What's invisible at the call site is that these objects are *designed* to be long-lived: they carry connection pools, keep-alive sockets, and token caches that only pay off across calls.

The failure has a second blade: server-side resource exhaustion. Per-request database connections at production concurrency blow through `max_connections`, and thousands of short-lived sockets pile up in TIME_WAIT. The slow version and the outage version are the same line of code at different traffic levels.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Reuse Expensive Clients and Connections

NEVER construct a connection-holding or handshake-performing object (database connection, HTTP client/session, gRPC channel, cloud SDK client, message-broker producer, search client) inside per-request or per-item code. These objects are designed to be created once and shared; they carry pools, keep-alive sockets, and token caches that only pay off across calls.

- Create clients at module scope, app startup, or via dependency injection with singleton lifetime; handlers and loop bodies receive the existing instance.
- Databases get a connection *pool* created once; per-request code borrows and returns. Constructing connections per request is both a latency tax (handshake per call) and an outage vector (max_connections exhaustion under load).
- Bare `requests.get()`/`fetch` calls in loops forfeit keep-alive: each call may re-handshake TCP+TLS. Use a `requests.Session`, `httpx.Client`, or the platform's pooled agent held across calls.
- Most official SDK clients (AWS, GCP, Stripe-style) are thread-safe and intended as singletons; check the docs and share one instance. Per-call construction can also re-trigger credential resolution against metadata endpoints, adding network calls you never see.
- If a client must be per-request (request-scoped auth), keep the *transport* shared (pooled connections under per-request credentials) where the library supports it.
- Verify at the connection layer: under a burst of requests, connection counts (`pg_stat_activity`, `netstat`/`ss` counting TIME_WAIT, client pool metrics) should be stable and small, not proportional to request count.

**Red flags that you're about to violate this:**
- "Creating the client in the function keeps it self-contained."
- "The SDK quickstart instantiates it right before the call."
- "Connections are cheap."
- "I don't want to deal with shared state or thread safety."
- "We close it right after, so nothing leaks."
- "It's one extra object per request, the GC handles it."

---

## Why It Works

1. **It names the object class by capability.** "Connection-holding or handshake-performing" gives the AI a test it can apply to unfamiliar SDKs, instead of a memorized list it will fall off of.
2. **It reframes the quickstart pattern as a scale bug.** The AI's strongest prior here is documentation examples; explicitly tagging per-call construction as a demo idiom severs "the docs do it" from "production does it."
3. **It pairs the latency cost with the outage cost.** Handshake overhead alone reads as tolerable; max_connections exhaustion makes the same line read as a reliability defect, which changes how seriously the rule is taken.
4. **It verifies with connection counts under burst.** Stable-and-small vs proportional-to-requests is a binary observable that a single-request test can never produce.

## Origin

A serverless-style API opened a fresh database connection inside every handler invocation, closed it neatly at the end, and passed every test. At a product-launch traffic spike, concurrent invocations exceeded the database's 100-connection limit in under a minute; new requests got connection-refused, retries amplified the stampede, and the database spent its CPU on TLS handshakes for connections that lived 40 milliseconds each. Moving to a shared pool (and a proxy in front of the database) ended a class of outage the team had been attributing to "database flakiness" for a quarter.
