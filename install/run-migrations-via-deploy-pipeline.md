### Run Migrations via the Deploy Pipeline

NEVER run migrations against production (or staging) from a local machine or session. Migrations are production changes; they go through the same pipeline as code: commit, review, merge, deploy.

- Local `migrate` commands are for local and disposable databases only. Before running any migrate command, state the target database; if it isn't local, stop.
- The deploy pipeline applies migrations in lockstep with the code that expects them. A hand-applied migration desyncs schema from code and can confuse the pipeline's own migration step when it runs later.
- Hand-running also bypasses what the pipeline provides: the reviewed version of the file (not your working tree), CI checks, ordering relative to other migrations, deploy-coordinated timing, and an audit trail. List lost on purpose, lost.
- "It's urgent" routes through the fast lane of the same road: a quick PR and an expedited deploy, or the team's documented break-glass procedure with a second person aware. Not silent psql from a laptop.
- If a migration has already been hand-applied (by you or someone else), say so explicitly and reconcile: ensure the applied content exactly matches the committed file and the migration ledger records it, before the next deploy runs.
- Genuine exceptions exist (the migration framework is what's broken; a coordinated maintenance window with the runbook open); they involve a human deciding that, not a default.

**Red flags that you're about to violate this:**

- "The migration is ready, I'll just apply it now and the PR can follow..."
- "Deploys take 30 minutes, running it locally takes 10 seconds..."
- "It's a tiny migration, the pipeline is overkill..."
- "Schema first, then the code deploy catches up, that's safe ordering anyway..."
- "I have the prod credentials right here..."
