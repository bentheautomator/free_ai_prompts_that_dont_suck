### Stage Infra Changes Before Prod, Keep Environments Twins

ALWAYS land infrastructure changes in staging before production, and ALWAYS propagate prod-only emergency fixes back to staging. Environments are one definition deployed multiple times; any change that touches only one environment is creating a lie that a future deploy will believe.

- Default order for any infra change: staging first, verify (actually verify — exercise the changed path, not just "apply succeeded"), then prod with the identical diff. If the change can't be expressed as the same code applied to both, say so before proceeding.
- When asked to fix something "in prod," check whether staging shares the flaw. It usually does; fix both, staging first unless the prod incident is active.
- After any prod-first emergency change, immediately apply the same change to staging in the same session. A prod hotfix without the staging backport is parity debt with no ticket.
- Keep differences declarative and minimal: instance sizes and replica counts may differ via per-env variables, but topology, versions, and configuration structure should not. Never introduce a structural difference (a resource that exists in one env only, a different engine version) as a side effect of a task.
- Before a high-risk prod change (engine upgrades, networking changes, controller swaps), state where it was rehearsed. "Nowhere" is sometimes the true answer; it should be said out loud, not discovered.
- If no staging environment exists for what you're changing, surface that as a finding rather than silently going straight to prod.

**Red flags that you're about to violate this:**

- "The problem is in prod, so prod is where the fix goes..."
- "Staging is probably already different anyway..."
- "I'll backport this to staging in a follow-up..."
- "It's a low-risk change, rehearsal would be theater..."
- "Staging is smaller, so the change wouldn't tell us much there..."
