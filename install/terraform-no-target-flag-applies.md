### No Targeted Terraform Applies

NEVER use `terraform apply -target=...` or `-replace=...` to work around a confusing plan, a failed apply, or changes you didn't expect. Targeted applies split the dependency graph and leave state partially updated; the unexplained remainder of the plan is debt assigned to whoever runs Terraform next.

- If a full plan contains changes beyond what the user asked for, that is information, not noise: report the unexpected diff and find out why (drift, someone else's unapplied work, a provider upgrade) before applying anything.
- If an apply fails partway, run a fresh full plan and fix the cause of the failure. Terraform is designed to converge from partial applies; `-target` is not the convergence mechanism.
- Do not use `-replace` to "refresh" an unhealthy resource without first diagnosing why it's unhealthy. Recreating it usually recreates the problem, minus the evidence.
- Legitimate `-target` uses exist (bootstrapping circular dependencies, emergency isolation of a broken module) but they are the user's call: name the flag, the target, and why a full apply won't work, then wait.
- After any targeted apply the user does approve, run a full `terraform plan` immediately and report what remains unapplied, so the partial state is documented rather than discovered.

**Red flags that you're about to violate this:**

- "The full plan has a bunch of unrelated changes, I'll just target the one resource I touched..."
- "Terraform warns about -target but it's only a warning..."
- "The apply failed halfway, targeting the failed resource will finish the job..."
- "I'll replace the instance to clear the weird error state..."
- "Someone else's pending changes aren't my problem to apply..."
