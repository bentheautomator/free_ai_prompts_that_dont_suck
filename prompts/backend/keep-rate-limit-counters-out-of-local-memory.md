---
title: Keep Rate-Limit Counters Out of Local Memory
slug: keep-rate-limit-counters-out-of-local-memory
category: backend
tags: [universal, backend]
works_with: all
severity: high
one_liner: "Stops per-replica counters from multiplying every limit by instance count"
---

# Keep Rate-Limit Counters Out of Local Memory

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents rate limits, quotas, and usage counters kept in process memory from silently becoming "the limit, times however many replicas are running."

**[Copy-paste ready version](../../install/keep-rate-limit-counters-out-of-local-memory.md)** — just the instruction block, no explanation.

## The Problem

"Add rate limiting: 100 requests per user per minute." The assistant writes a `Map` of user ID to counter, checks it in middleware, resets it on a timer. Locally, it's textbook: the 101st request gets a 429, the test passes, ship it. The implementation has one unstated assumption — that this process sees all the traffic. In production behind a load balancer with six replicas, each process keeps its own private ledger. A user's requests spread across replicas, each counter sees a sixth of them, and the real limit is now 600. Scale to twelve pods during a traffic spike — precisely when limits matter most — and it's 1,200. Your rate limit weakens in exact proportion to how badly it's needed.

The same bug wears other hats: free-tier usage quotas counted per pod (customers get N× their plan), "max 3 concurrent exports per account" enforced per replica, abuse lockouts after 5 failed logins that an attacker resets by simply hitting a different pod, feature counters that report a sixth of true usage to billing. And every deploy or restart zeroes all of it, so limits also reset whenever you ship.

Assistants reach for the in-memory map because the prompt says "count requests" and a map is how you count things — in a single process. Dev runs a single process. The horizontal dimension isn't in the prompt, the test, or the demo; it's only in production.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Rate-Limit Counters Out of Local Memory

NEVER enforce a rate limit, quota, or usage counter with process-local state in a service that can run more than one instance. Each replica counting privately means the effective limit is `limit × replicas`, it resets on every deploy, and it loosens exactly when you scale up under attack.

- Keep enforcement counters in a shared store with atomic operations: Redis `INCR` + `EXPIRE` (atomically, via pipeline or Lua), a token-bucket script, or your gateway's built-in distributed limiter. The check-and-increment must be one atomic step — read-modify-write from N replicas undercounts under concurrency.
- This covers every counter with consequences: per-user rate limits, plan quotas, failed-login lockouts, "max N concurrent jobs per account," coupon redemption caps, anything billed.
- Prefer enforcing at a layer built for it when available (API gateway, ingress rate limiting, CDN) and keep application-level limits for business quotas the edge can't see.
- Decide the limiter's failure mode explicitly: if the shared store is down, fail open (allow, log loudly) for revenue paths and fail closed for abuse/security paths (lockouts). Silence is the only wrong option.
- Local memory is acceptable only as a layered pre-filter (e.g., a per-instance cap to shed egregious floods before the Redis hop) — never as the authoritative count, and say so in a comment.
- Include the window design: fixed windows allow 2× bursts at boundaries; use sliding windows or token buckets when the limit actually matters.

**Red flags that you're about to violate this:**
- "A simple in-memory map keeps this dependency-free."
- "We only run one instance of this service." (Confirm the deployment, then ask about next quarter.)
- "Per-instance limiting is roughly the same thing."
- "Sticky sessions mean each user hits the same pod anyway." (Until a pod dies, scales, or deploys.)
- "It's just a soft limit, accuracy doesn't matter." (Then why is billing reading it?)
- "Redis adds latency to every request." (One INCR is sub-millisecond; quota fraud is not.)

---

## Why It Works

1. **It exposes the multiplication.** "Limit × replicas" is the actual behavior of the in-memory version, but nothing at write time displays it. Naming the formula makes the bug visible in code review without needing a load test.
2. **It demands atomicity, not just sharedness.** Moving the counter to Redis but keeping read-then-write logic still undercounts under concurrent requests; specifying atomic INCR closes the second-order bug hiding inside the fix.
3. **It forces a failure-mode decision.** Distributed limiters add a dependency; deciding open-vs-closed per path at design time prevents both "Redis blip locked out all logins" and "Redis blip disabled abuse protection" from being discovered live.
4. **It scopes the rule by consequence.** Tying it to counters that gate money, abuse, or capacity keeps the assistant from either ignoring it or Redis-ifying every harmless debug counter.

## Origin

A SaaS metered free-tier API calls in process memory, synced to billing hourly. The service ran eight replicas, so free customers received roughly eight times their quota — and the daily deploy reset whatever the counters had accumulated. The discrepancy surfaced when finance noticed conversion to paid plans was inexplicably low: the free tier was, in practice, nearly unlimited. The estimated revenue gap had four zeroes before anyone moved the counter into Redis.
