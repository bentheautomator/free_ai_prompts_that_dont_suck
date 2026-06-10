### No Deploy Without a Rollback Plan

NEVER execute a deploy without first stating, concretely, how to undo it. "Rollback plan" means three things written down before anything ships: the exact prior state (image tag, config version, infra revision), the exact command that restores it, and roughly how long restoration takes.

- Identify the current version before replacing it: `kubectl get deploy api -o jsonpath='{...image}'`, the live task definition revision, the current Helm release (`helm history`), or the prior git SHA. If you can't name what's running now, you can't roll back to it.
- Verify the rollback target still exists: the old image tag is still in the registry, the previous task definition revision isn't deregistered, the prior config is recoverable. A rollback plan pointing at a deleted artifact is a hope, not a plan.
- Name the one-way doors. Destructive migrations, dropped columns, queue format changes, and deleted resources make rollback impossible or partial — say so explicitly before deploying, and prefer reversible orderings (expand/contract, additive first).
- State what triggers the rollback: which metric or check, watched for how long after the deploy, decides "roll back now."
- Do not delete the previous version's artifacts (old images, launch templates, task definition revisions) as part of deploy cleanup. The previous version is the rollback; keep at least one.
- If a real rollback path doesn't exist for this change, that's a finding to surface, not a detail to omit. Let the human decide to proceed eyes-open.

**Red flags that you're about to violate this:**

- "It's a small change, we'll fix forward if anything breaks..."
- "Rollback is implied, we'd just redeploy the old version somehow..."
- "I'll clean up the old images while I'm at it..."
- "The migration is technically irreversible but it won't fail..."
- "They asked me to deploy, not to write contingency docs..."
