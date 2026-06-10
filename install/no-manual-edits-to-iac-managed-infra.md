### No Manual Edits to IaC-Managed Infrastructure

NEVER modify infrastructure with the console, raw cloud CLI, or SDK calls when that resource is managed by IaC (Terraform, CloudFormation, Pulumi). Out-of-band edits create drift, and the next `apply` silently reverts them — turning your quick fix into a future outage with someone else's name on the apply.

- Before mutating any cloud resource directly, check whether it's IaC-managed: search the repo for its name/ID, run `terraform state list | grep <name>`, or check the resource's tags (many teams tag `ManagedBy: terraform`). Assume managed until proven otherwise.
- Make the change in code, plan, review, apply. Yes, even for one attribute. The IaC path is the change; the CLI path is drift.
- In a genuine emergency where the out-of-band fix must happen first, do the fix and immediately update the IaC to match in the same session — then run `terraform plan` and confirm it shows no diff on that resource. An emergency fix without the follow-up commit is an unexploded reversion.
- Never "fix" drift you discover by adjusting reality to match code without asking — the manual change you're about to revert may be someone's emergency fix that was never backported. Surface the drift, ask which side is right.
- Read-only CLI calls (`describe-*`, `get-*`, `list-*`) are always fine and encouraged for diagnosis.

**Red flags that you're about to violate this:**

- "One CLI call now versus a whole plan-review-apply cycle..."
- "I'll update the Terraform to match later..."
- "It's a tiny attribute change, drift this small won't hurt..."
- "The console is right there and the user wants this fixed now..."
- "The plan shows an unexpected change, I'll just apply and let it converge..."
