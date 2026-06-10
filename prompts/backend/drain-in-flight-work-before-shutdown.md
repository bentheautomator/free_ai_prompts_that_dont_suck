---
title: Drain In-Flight Work Before Shutdown
slug: drain-in-flight-work-before-shutdown
category: backend
tags: [universal, backend, deployment]
works_with: all
severity: high
one_liner: "Stops deploys from killing requests and jobs mid-flight with no graceful drain"
---

# Drain In-Flight Work Before Shutdown

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents services that die instantly on shutdown, dropping in-flight requests and half-finished jobs on every single deploy.

**[Copy-paste ready version](../../install/drain-in-flight-work-before-shutdown.md)** — just the instruction block, no explanation.

## The Problem

AI assistants write servers that start beautifully and stop like a power cut. The generated entrypoint calls `app.listen()` or starts a worker loop, and that's the end of the lifecycle story. When the orchestrator sends SIGTERM during a deploy, the process exits immediately: requests that were mid-handler get a connection reset, a job that was 80% through its work just stops, and the response the client was waiting on never arrives.

This is invisible in development because nobody deploys their dev server under load. In production it means every deploy is a small outage — a burst of 502s, a handful of jobs that ran halfway, a payment that was charged but whose confirmation step never ran. Teams learn to "deploy during low traffic" as a ritual, which is just graceful shutdown implemented as a calendar entry.

The fix is boring and well-known: stop accepting new work, finish what's in flight within a deadline, then exit. Assistants skip it because the happy path — process runs forever — is all the dev environment ever exercises.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Drain In-Flight Work Before Shutdown

Every server and worker MUST shut down gracefully: on SIGTERM, stop accepting new work, finish in-flight work within a deadline, then exit. NEVER let process exit be the default termination behavior — orchestrators send SIGTERM on every deploy, scale-down, and node rotation, so abrupt exit drops live requests routinely, not rarely.

- HTTP servers: on SIGTERM, stop accepting new connections, let in-flight requests complete (use the framework's graceful close — `server.close()`, `srv.Shutdown(ctx)`, uvicorn/gunicorn graceful timeout), then exit 0.
- Workers: finish or cleanly abort the current message before exiting. Stop polling first, then drain. A message killed mid-processing should be unacked or returned so another worker picks it up.
- Always bound the drain with a deadline shorter than the orchestrator's kill grace period (Kubernetes defaults to 30s before SIGKILL). Drain forever and you get SIGKILLed mid-drain anyway, which is the original bug with extra steps.
- During the drain, the readiness probe must start failing so the load balancer stops routing new traffic. Draining while still in the pool means you're rejecting requests you were just handed.
- Don't start un-finishable work near shutdown: check a shutting-down flag before picking up new jobs.
- Wire this into the entrypoint now, not "when we productionize." It's ten lines.

**Red flags that you're about to violate this:**
- "The orchestrator handles shutdown for us."
- "Requests are fast; the odds of one being in flight are low."
- "I'll add signal handling once the core logic works."
- "SIGKILL can happen anyway, so graceful handling is pointless."
- "Deploys happen at night when traffic is low."
- "The job runner framework probably does this out of the box."

---

## Why It Works

1. **It reframes shutdown frequency.** Assistants treat termination as an exceptional event; naming that SIGTERM arrives on *every* deploy makes "drop in-flight work" a per-deploy defect rather than a rare crash scenario.
2. **It specifies the sequence** (stop accepting → drain → deadline → exit), which prevents the half-fix of catching SIGTERM and just logging "shutting down" before exiting anyway.
3. **It bounds the drain.** The naive graceful version waits indefinitely and gets SIGKILLed; the explicit deadline-under-grace-period detail is what makes the implementation actually survive contact with an orchestrator.
4. **It links shutdown to readiness**, closing the gap where a draining instance still receives traffic from the load balancer and refuses it.

## Origin

A document-export service ran exports that took 20 to 90 seconds. Its deploy pipeline shipped several times a day, and every ship hard-killed whatever exports were running; users saw a spinner that never resolved and clicked export again. Support tickets blamed "random export failures" for months. Correlating failure timestamps with deploy timestamps took one afternoon; the graceful drain fix took fifteen lines and a readiness probe change.
