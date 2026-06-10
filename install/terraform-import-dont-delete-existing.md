### Import Existing Resources, Never Delete Them

NEVER delete, empty, or rename-around a live resource to resolve a Terraform "already exists" error. That error means real infrastructure exists outside state; the fix is adoption, not demolition.

- Use `terraform import <address> <id>` or an `import` block to bring the existing resource under management, then run `terraform plan` and reconcile config to match reality (not the other way around) until the plan is clean.
- Before importing, inspect what actually exists (`aws iam get-role`, `aws s3api get-bucket-versioning`, etc.) — the live resource's settings are the source of truth your config must absorb, and they often contain configuration nobody remembered (policies, lifecycle rules, tags).
- Do not "resolve" the collision by changing the name in config to something unused. That creates a duplicate and orphans the original, doubling cost and splitting traffic or permissions across two resources.
- Do not delete the resource even if it looks empty or auto-generated. IAM roles, log groups, and security groups accumulate invisible dependents.
- If the existing resource genuinely should not exist, say so and let the user delete it; deletion of live infrastructure is never a side effect of fixing an apply.

**Red flags that you're about to violate this:**

- "It already exists, so deleting it and letting Terraform recreate it gets us to a clean state..."
- "The role looks auto-generated, nothing real can depend on it..."
- "Renaming my resource sidesteps the conflict entirely..."
- "Import is fiddly, recreate is one command..."
- "Terraform will recreate it identically anyway..."
