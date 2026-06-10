---
title: Separate Readiness From Liveness Checks
slug: separate-readiness-from-liveness-checks
category: backend
tags: [universal, backend, reliability]
works_with: all
severity: high
one_liner: "Stops one failing dependency from restart-looping your healthy instances"
---

# Separate Readiness From Liveness Checks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a single `/health` endpoint from either restart-looping healthy services or routing traffic to instances that can't serve it.

**[Copy-paste ready version](../../install/separate-readiness-from-liveness-checks.md)** — just the instruction block, no explanation.

## The Problem

Ask an assistant to "add a health check" and you get one endpoint, `/health`, wired to everything the orchestrator offers. Two equally bad versions exist. Version one returns `200 OK` unconditionally — so an instance that lost its database connection or hasn't finished loading its config keeps receiving traffic and erroring on every request. Version two checks the database, Redis, and a downstream API, and returns 500 if any of them blink — which sounds diligent until you wire it into a Kubernetes liveness probe.

Version two is the one that causes the legendary incidents. Liveness failure means "restart this container." So when the database has a 90-second blip, every instance's `/health` starts failing, and the orchestrator helpfully kills and restarts your entire fleet. The restarts cause cold caches, connection-pool stampedes against the recovering database, and a thundering herd of startup traffic — converting a 90-second dependency wobble into a 40-minute self-inflicted outage. Restarting your process does not fix someone else's database, but the probe config just promised the orchestrator it would.

Assistants conflate the two because the distinction is operational, not functional: in dev there's no orchestrator killing pods and no load balancer pulling instances, so one endpoint looks as good as two.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Separate Readiness From Liveness Checks

ALWAYS expose two distinct health endpoints with distinct meanings. Liveness answers "should this process be restarted?" Readiness answers "should this instance receive traffic right now?" Wiring one endpoint to both questions guarantees a wrong answer to one of them.

- Liveness (`/livez`): checks only the process itself — event loop responsive, not deadlocked. It must NOT check databases, caches, or downstream services. Restarting your process never fixes a dependency, and a liveness probe that checks dependencies converts every dependency blip into a fleet-wide restart loop.
- Readiness (`/readyz`): checks whether this instance can serve real requests — config loaded, migrations verified, connection pools established, critical dependencies reachable. Failing readiness removes the instance from rotation without killing it, and it rejoins automatically when the check passes.
- Only include *hard* dependencies in readiness — ones without which every request fails. A degraded optional dependency (recommendations, email) should degrade responses, not remove instances. If all instances share a failed dependency, readiness pulling all of them is still an outage; consider whether serving errors or serving nothing is worse for that dependency.
- Keep both endpoints fast (sub-second, cached status if needed), unauthenticated from the orchestrator's network, and free of side effects.
- Fail readiness during startup until initialization completes, and during shutdown as the first step of draining — that's what makes rolling deploys zero-downtime.
- Make liveness lenient (high failure threshold) and readiness sensitive. Restarts are expensive and destructive; rotation changes are cheap and reversible.

**Red flags that you're about to violate this:**
- "One /health endpoint is enough, I'll point both probes at it."
- "The health check should verify the database, to be thorough." (In *readiness*. Only readiness.)
- "Return 200 always so the deploy passes."
- "If the dependency is down the pod is useless, might as well restart it."
- "I'll add the downstream API to the check too, we depend on it." (Hard dependency, or nice-to-have?)
- "Probes are an ops concern, I'll leave the defaults."

---

## Why It Works

1. **It maps each check to its consequence.** The two probes trigger different remediations (restart vs. de-route); the rule forces the assistant to ask "would a restart fix this?" before putting a check behind the restart trigger.
2. **It prevents failure amplification.** Dependency-checking liveness multiplies one failure into N restarts plus cold-start load on the recovering dependency — the exact mechanism behind most "the outage was worse because of our health checks" postmortems.
3. **It makes deploys and shutdowns graceful by construction.** Readiness-fail-on-startup and on-drain is the primitive that rolling updates are built from; without it, every deploy drops requests.
4. **It forces the hard-vs-soft dependency inventory.** Deciding which dependencies belong in readiness is a design review of the service's actual failure modes, done at write time instead of incident time.

## Origin

A platform team wired a `/health` endpoint that pinged Postgres into both probes across forty services. A managed-database failover caused ninety seconds of connection errors; liveness probes failed everywhere, and the orchestrator rolling-restarted roughly six hundred pods. The database recovered in two minutes — the platform took thirty-five more to climb out from under the restart stampede it had ordered for itself. The fix was renaming, splitting, and a one-line probe config change per service.
