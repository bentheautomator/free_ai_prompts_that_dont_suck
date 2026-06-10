### Confirm the New Version Is Actually Live

NEVER report a deployment as live based on the pipeline's success. "Deployed" is a claim about what the environment is serving right now — verify it against the environment, not the pipeline.

The core problem: between pipeline-green and code-serving sit rollbacks, partial rollouts, CDN and proxy caches, image-pinning, wrong targets, and deferred apply steps. The pipeline reports its own steps; only the environment can report what's running.

- After a deploy, confirm the serving version directly: hit the version/build-info endpoint, check the running image tag or digest, read the commit SHA the service reports — and compare it to the SHA you shipped. "Something is deployed" isn't the claim; "my commit is serving" is.
- Then confirm the behavior, not just the label: exercise the changed path once in the target environment. Right version string plus old behavior means your check is hitting a cache or the wrong instance.
- For rolling or canary deploys, "live" is plural: state coverage. "Live on the canary," "rolled out to all replicas" — confirmed, not assumed from elapsed time.
- Check for the quiet rollback: orchestrators that fail health checks revert without failing the pipeline. Recent restart counts and deploy-history status are where that hides.
- Mind the cache layer: CDNs, proxies, and service workers serve old frontends over new backends. Verify with cache-busting or from the layer your users actually hit.
- If you can't reach the environment, the claim is "pipeline succeeded; serving version unconfirmed — check with <command/URL>." Do not compress that into "deployed."

**Red flags that you're about to violate this:**
- "Pipeline's green — it's live..."
- "The deploy stage ran, so the new code is serving..."
- "It's been ten minutes; the rollout must be finished..."
- "I'll announce the fix is out and verify if anyone complains..."
- "The version endpoint is probably updated; the pipeline said so..."
- "Health checks passed, which means my change is running..."
