---
title: Keep Session State Out of Process Memory
slug: keep-session-state-out-of-process-memory
category: backend
tags: [universal, backend, scaling]
works_with: all
severity: high
one_liner: "Stops in-memory sessions and caches from breaking the moment you run two replicas"
---

# Keep Session State Out of Process Memory

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents sessions, counters, and caches stored in process memory that silently break the moment the service runs more than one instance.

**[Copy-paste ready version](../../install/keep-session-state-out-of-process-memory.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant for session handling, rate limiting, or a cache, and the first draft is almost always a dictionary at module scope: `sessions = {}`, `request_counts = defaultdict(int)`, an LRU map guarding an expensive call. It works flawlessly on a laptop, in CI, and in staging with one replica. Every test passes because every test talks to the same process.

Then production runs three replicas behind a load balancer. A user logs in on instance A and gets a 401 from instance B. The rate limiter allows 3x the configured limit because each replica counts independently. Cache invalidation "works" on one instance and serves stale data from the other two. None of this throws an error; it shows up as intermittent, user-specific weirdness that takes days to trace because every individual instance is behaving exactly as written.

Assistants default to this because in-process state is the shortest path to working code, and nothing in the dev environment punishes it. The bug isn't in any line of code — it's in the assumption that there is one process.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Session State Out of Process Memory

NEVER store cross-request state — sessions, auth tokens, rate-limit counters, feature locks, shared caches — in process memory in a service that can run more than one instance. Assume every service will be horizontally scaled and restarted; in-process state silently diverges between replicas and evaporates on every deploy.

- Sessions and tokens go in a shared store (Redis, the database) or in signed tokens carried by the client. A `sessions = {}` dict at module scope is a bug, not a placeholder.
- Rate limiters and quotas count in a shared store with atomic operations. Per-process counters multiply every limit by the replica count.
- Anything mutated by one request and read by another (dedupe sets, "already sent" flags, in-flight job registries) must live somewhere all replicas can see.
- In-process caches are acceptable only for data that is immutable or harmlessly stale, and the cache must be a pure performance layer: the code must be correct with the cache removed.
- Do not "fix" this with sticky sessions unless explicitly asked. Stickiness hides the problem until a replica dies and takes its state with it.
- When local state is genuinely fine (per-request scratch data, config loaded at boot), keep it local. The rule is about state that outlives one request.

**Red flags that you're about to violate this:**
- "A simple in-memory map is fine for now; we can move it to Redis later."
- "This service probably only runs as a single instance."
- "The load balancer likely has sticky sessions enabled."
- "It's just a counter, it doesn't need to be exact."
- "Adding Redis for this one feature feels like over-engineering."
- "It works in staging, and staging mirrors production."

---

## Why It Works

1. **It changes the default assumption.** Assistants implicitly model "the service" as one process because that's what dev and tests look like. Stating "assume every service is horizontally scaled" makes multi-replica the baseline the code must satisfy, not an edge case.
2. **It names the disqualifying pattern literally.** Calling out `sessions = {}` as a bug catches the exact code shape assistants generate, at the moment they generate it.
3. **It closes the "later" escape hatch.** "Move it to Redis later" is the rationalization that ships the bug; the rule says the shared store is the first version, not the upgrade.
4. **It defines when local state is legitimate** (per-request, boot-time, harmlessly-stale cache), so the rule can't be dismissed as dogma and applied to nothing.

## Origin

A checkout service kept "discount code already redeemed" flags in a process-local set. Single instance for a year, no problems. A traffic bump scaled it to four replicas, and a promo code limited to one use per account was redeemed up to four times per account for a weekend — once per replica. Nothing errored, nothing alerted; finance found it in reconciliation three weeks later.
