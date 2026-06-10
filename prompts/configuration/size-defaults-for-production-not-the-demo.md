---
title: Size Defaults for Production, Not the Demo
slug: size-defaults-for-production-not-the-demo
category: configuration
tags: [universal, config, defaults]
works_with: all
severity: critical
one_liner: "Stops laptop-scale defaults like unbounded queues from reaching prod traffic"
---

# Size Defaults for Production, Not the Demo

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from choosing config defaults that behave perfectly in development and detonate at production scale — unbounded queues, missing limits, toy-sized pools.

**[Copy-paste ready version](../../install/size-defaults-for-production-not-the-demo.md)** — just the instruction block, no explanation.

## The Problem

The AI adds an in-memory cache: `max_entries` defaults to unlimited, because limits would complicate the demo. A retry policy: no backoff cap, because in dev the service recovers instantly. An upload endpoint: no size limit, because the test file is 2KB. A worker pool: 4, because that saturated the laptop. Every one of these defaults is *correct* in the environment where it was chosen and *load-bearing* in the environment that matters — and defaults have gravity. Most environments never override most keys, so the default you pick in a dev session is, statistically, the value production runs.

AI assistants pick dev-flattering defaults because their feedback loop ends at "works in the environment I can observe." Unbounded is simpler than bounded, and nothing in a dev run punishes unbounded. The punishment arrives months later as an OOM kill at peak traffic, a retry storm during a downstream outage, or a 4-worker pool serving a fleet's worth of load — failures whose timing guarantees the config decision is long forgotten.

The discipline is to choose every default by asking what it does at production scale and during failure, and to make genuinely environment-dependent values *required* rather than defaulted.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Size Defaults for Production, Not the Demo

When choosing a default for any capacity, limit, or rate config, ALWAYS ask: what does this value do at production load, during a downstream outage, on the biggest tenant? The default is what production will run, because most deployments never override most keys.

"Works in dev" is the weakest possible evidence about a default — dev traffic can't punish a bad one.

- Anything that accumulates gets a bound by default: caches, queues, buffers, batch sizes, in-flight request counts. Unbounded is not a default; it's an outage with patience. If a bound feels arbitrary, a generous explicit bound still beats none.
- Anything that retries gets a cap and backoff by default: max attempts, max total time, jitter. Default-infinite retries are a self-inflicted DDoS waiting for a downstream blip.
- Anything that accepts input gets a size limit by default: request bodies, uploads, line lengths, array counts.
- Pools and concurrency sized for "my machine" are not defaults — if the right value depends on the deployment, make the key required (fail at startup when unset) instead of guessing small.
- Don't weaken an existing safety default to make dev pleasant. Loosen it in the dev overlay; the shared default stays production-safe.
- State your reasoning when you pick a default: "default 10MB body limit; raise per-environment if needed" is a decision someone can review. A bare number is not.

**Red flags that you're about to violate this:**
- "Unlimited is fine, the cache never gets big."
- "I tested it and memory usage was tiny."
- "Production will obviously override this."
- "A limit might break someone's legitimate use case, so no limit."
- "Four workers handled all my test load."
- "Retry forever — it should be resilient."

---

## Why It Works

1. **It names the gravity of defaults:** overriding requires knowing a key exists, so defaults silently become the production values. Once the AI accepts that premise, "what does this do at scale" stops being optional diligence.
2. **The required-instead-of-guessed rule converts unanswerable sizing questions into startup errors,** which is the correct place for "depends on your deployment" to be resolved — by the deployer, not by whatever number fit the demo.
3. **Per-category rules (accumulates→bound, retries→cap, accepts→limit) are checkable at generation time** without load testing, which the AI can't do anyway.
4. **Splitting dev comfort into the dev overlay** preserves the convenience that motivates weak defaults without letting the convenience ship.

## Origin

A notification service's outbound queue had no depth limit — the default chosen when the whole system was a prototype handling test events. A downstream email provider had a 40-minute outage; the queue absorbed every undelivered message into memory, exactly as configured. The service OOM-killed across the fleet, dropping not just email but the webhooks and SMS jobs sharing the process. Postmortem finding: the provider outage cost nothing; the unbounded default turned it into a four-channel notification blackout. The fix was a number — any number — in a field that had defaulted to infinity for two years.
