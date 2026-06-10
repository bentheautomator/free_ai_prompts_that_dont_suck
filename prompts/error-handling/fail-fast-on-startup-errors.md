---
title: Fail Fast on Startup Errors
slug: fail-fast-on-startup-errors
category: error-handling
tags: [universal, errors]
works_with: all
severity: high
one_liner: "AI deferring startup failures so broken services boot green and fail later"
---

# Fail Fast on Startup Errors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents services from booting "healthy" with broken dependencies that fail on the first real request.

**[Copy-paste ready version](../../install/fail-fast-on-startup-errors.md)** — just the instruction block, no explanation.

## The Problem

The database connection fails during boot, and the AI's initialization code catches it: `logger.warning("DB unavailable, will retry on first use"); self.db = None`. The service starts, the port opens, the health check returns 200, the deploy pipeline declares success and rolls the old version away. Then the first real request arrives and hits `self.db = None`. So does the second. The service is a zombie — alive by every operational signal, dead at its actual job — and the deploy that broke it has already been marked green.

Assistants engineer this on purpose, because "the service should start even if a dependency is down" sounds like resilience. Sometimes it is, for optional dependencies. But for required ones, deferring the failure moves it from the best possible moment — boot, during a deploy, while the pipeline is watching and rollback is one click — to the worst: first user traffic, after the watchers have moved on. A crash loop at startup is loud, attributed, and automatically handled by orchestrators. A lazy failure is quiet, mysterious, and handled by customers.

The same logic produces deferred config validation ("we'll check it when it's used") and lazily-initialized clients that hide bad credentials until the first call.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fail Fast on Startup Errors

If a service cannot do its job, it must refuse to start. NEVER catch a required-dependency failure at boot and continue to a "running" state — crash loudly while the deploy is still watching.

- Validate at startup, before reporting healthy: required config present and well-formed, database reachable, required credentials accepted, migrations at expected version
- A failed required initialization must terminate the process with a clear message (`FATAL: cannot connect to postgres at db:5432: connection refused`), not log a warning and set the client to None
- Do not lazily initialize required dependencies to dodge boot failures; lazy init converts a deploy-time crash (cheap, attributed, auto-rolled-back) into a request-time outage (expensive, mysterious)
- Optional dependencies may degrade — but "optional" is a product decision, stated in code (`# feature X disabled without redis; core flows unaffected`), not a label applied to whatever happened to fail
- Readiness endpoints must reflect real ability to serve: a process that opened its port but lacks its database is not ready and must not report ready
- Crash-looping on a down dependency is acceptable behavior under orchestration — the orchestrator backs off and retries, the deploy fails visibly, the old version keeps serving; do not "fix" the crash loop by swallowing the error

**Red flags that you're about to violate this:**
- "The service should still start even if the DB is down..."
- "I'll initialize it lazily on first use..."
- "A warning at boot is enough; it might recover..."
- "Health checks should pass so the deploy goes through..."
- "Crashing at startup looks bad..."

---

## Why It Works

1. **It compares the two failure moments explicitly.** The model sees only the boot crash it's preventing, not the request-time outage it's scheduling. Putting both on the table — watched deploy vs. unwatched traffic — reverses which one looks like the bug.

2. **It rehabilitates the crash loop.** Models treat a crash-looping pod as a malfunction to suppress; explaining that orchestrators are *designed* around it (backoff, failed rollout, old version intact) removes the motivation to hide it.

3. **It makes "optional" a claim that must be written down.** The slide from "this dependency failed" to "this dependency was optional" happens silently in generated code; requiring the in-code justification stops the reclassification-by-convenience.

4. **It ties health endpoints to capability.** "Port open" is the model's implicit definition of healthy; redefining ready as "can actually serve" closes the gap the zombie service lives in.

## Origin

A deploy went out where a renamed environment variable left the message-broker URL unset. The AI-written startup code caught the connection failure, logged "broker unavailable, continuing," and started anyway; health checks passed and the pipeline retired the old pods. Every order-confirmation event for the next six hours was published into a dead client that dropped them — no crash, no alert, just a growing pile of customers who paid and never got confirmations. A startup crash would have failed the rollout in under a minute with the old version still serving.
