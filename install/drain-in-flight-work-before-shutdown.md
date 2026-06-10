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
