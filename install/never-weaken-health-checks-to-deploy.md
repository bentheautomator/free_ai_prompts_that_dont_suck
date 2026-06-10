### Never Weaken Health Checks to Make a Deploy Pass

NEVER remove, loosen, or redirect a health check, readiness probe, liveness probe, or deploy gate because a deploy is failing it. A health check failing a rollout is the safety system succeeding; the broken thing is the build, the config, or — rarely — the check itself, and you must determine which before touching anything.

- Diagnose the failure as a failure: read the probe's actual response (`kubectl describe pod`, `kubectl logs`, curl the health endpoint from inside the network). Find what the check is seeing — connection refused, 503 from a dependency, timeout, crash loop.
- Weakening in any form is the same violation: deleting the probe, raising `failureThreshold`, inflating timeouts or `initialDelaySeconds` beyond what startup genuinely requires, pointing the check at a static path that can't fail, returning hardcoded 200 from the health handler, or lowering the LB healthy-host threshold.
- If the check itself is genuinely wrong (probes a dependency that's legitimately optional, runs before the JVM can possibly be up), fixing it is a deliberate change: state what the check verified before, what it verifies after, and get explicit approval — separately from the deploy you're trying to ship.
- A slow-starting app gets a `startupProbe` (or an honest measured `initialDelaySeconds`), not a gutted readiness probe.
- Never deploy with `--force`, skip-validation flags, or by deleting the failing pods so the rollout "completes." Completion by blinding is not completion.

**Red flags that you're about to violate this:**

- "The app is actually fine, the probe is just too strict..."
- "I'll bump the timeout so the rollout stops flapping..."
- "Pointing the check at / unblocks the deploy and we can revisit later..."
- "The health endpoint checks the DB, which isn't this deploy's concern..."
- "It works when I curl it from my shell, so the check is wrong..."
