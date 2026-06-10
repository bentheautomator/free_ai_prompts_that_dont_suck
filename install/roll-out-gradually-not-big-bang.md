### Roll Out Gradually, Not Big Bang

NEVER configure or execute a deploy that replaces all serving capacity in one step. New code's first contact with production traffic must be partial, observed, and abortable.

- In Kubernetes, default to `RollingUpdate` with `maxUnavailable: 0` and a modest `maxSurge` (e.g. 25%); never set `strategy: Recreate` for a traffic-serving Deployment unless the app genuinely cannot run two versions concurrently — and say so if that's the claim.
- Between phases, observe: error rate, latency, and the deploy-relevant metric, for long enough to mean something (minutes of real traffic, not "the pods are Ready"). Readiness gates catch crash loops; only traffic catches wrong answers.
- Use the platform's native gradual mechanisms instead of hand-rolling: ASG instance refresh with batch sizes and health checks, weighted target groups, CodeDeploy/Argo Rollouts canary steps, per-service traffic splitting.
- Never remove, shorten, or skip an existing canary phase, bake time, or rollout pause to make a deploy faster — those settings are someone's post-incident scar tissue. Changing them is its own reviewed change, not a deploy-time convenience.
- Version skew is a feature requirement, not an excuse: if old and new genuinely can't coexist (schema, protocol), the fix is expand/contract sequencing, not Recreate.
- Big-bang is occasionally legitimate (single-replica services, true breaking cutovers, emergency patches). Name the reason, state the blast radius — "all traffic moves at once; rollback takes N minutes" — and get the human's yes.

**Red flags that you're about to violate this:**

- "Recreate is cleaner, no version-skew headaches..."
- "The change is tiny, a canary phase is ceremony..."
- "Tests passed, gradual rollout just delays the same outcome..."
- "I'll set the canary wait to zero so the pipeline finishes in this session..."
- "Both versions briefly running might cause weirdness, safer to stop everything first..."
