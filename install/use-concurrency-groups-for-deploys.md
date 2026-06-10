### Use Concurrency Groups for Deploys

Every job that deploys to, migrates, or mutates a shared environment MUST declare concurrency control naming that environment. NEVER ship a deploy workflow where two runs can act on the same target simultaneously or complete out of order.

Deploys race by default: a slow run of an old commit can finish after a fast run of a new one, silently un-deploying the newer code.

- GitHub Actions: set `concurrency: { group: deploy-production, cancel-in-progress: false }` on the deploy job or workflow. GitLab: `resource_group: production`. Jenkins: `disableConcurrentBuilds()`. Key the group by target environment, so staging and production don't queue behind each other but two production deploys can never overlap.
- Choose the queued-run policy deliberately. For deploys, `cancel-in-progress: false` (queue and run latest after) is usually right; cancelling a deploy mid-flight can strand the environment half-updated. For PR test workflows, `cancel-in-progress: true` keyed by `${{ github.ref }}` is right — superseded test runs are pure waste. Don't copy one job's policy onto the other kind.
- Concurrency groups serialize runs but don't enforce ordering. If out-of-order completion matters (it does, for deploys), add a freshness guard in the deploy step: compare the commit being deployed against what the environment currently runs, and refuse to deploy an ancestor over a descendant.
- Apply the same rule to anything else that mutates shared state from CI: database migrations, infrastructure apply steps (terraform), cache-warming jobs, release publishing.
- If you find an existing deploy workflow without concurrency control, flag it — it has been racing this whole time, win or lose.

**Red flags that you're about to violate this:**

- "Merges are infrequent here; two deploys won't overlap."
- "The deploy step is fast, so the race window is tiny."
- "I ran the workflow and it deployed fine."
- "cancel-in-progress: true everywhere — newer is always better, right?"
- "The platform probably serializes runs of the same workflow automatically."
