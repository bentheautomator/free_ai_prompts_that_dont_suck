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
