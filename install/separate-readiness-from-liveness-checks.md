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
