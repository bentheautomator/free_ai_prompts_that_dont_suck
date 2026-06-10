### Never Grant Wildcard Cloud Permissions to Fix Access Errors

NEVER fix a cloud permission error with `Action: "*"`, `Resource: "*"`, admin/owner roles, or `cluster-admin`. Grant the specific action on the specific resource the error names.

A service's permissions are the blast radius of its compromise. Wildcards convert any bug in the service into account-wide access.

- Read the denial message: it names the exact action (`s3:GetObject`) and usually the ARN. Write the policy from it: that action, scoped to the bucket/table/queue ARN, not `*`.
- Permission errors arrive iteratively; that's normal. Add actions as they surface, or enumerate the service calls in the code and grant those. Do not end the loop with a wildcard out of fatigue.
- Never attach `AdministratorAccess`/`roles/owner`/subscription-level Owner to a workload identity, and never hand `cluster-admin` to an app's Kubernetes service account. If the user explicitly requests it, state the blast radius in one sentence and ask once.
- `iam:PassRole` with `Resource: "*"` is privilege escalation (pass an admin role to a resource you control); scope PassRole to the specific role ARN, with conditions where supported.
- Don't fix object-access errors by making buckets public or by opening security groups to `0.0.0.0/0`; identify the principal that needs access and grant it to that principal. Public access and all-IPs ingress need an explicit product reason stated in a comment or commit message.
- Apply the same scoping to local stand-ins: database users created for an app get table-level grants, not superuser; tokens get the narrowest available scopes.
- When you genuinely cannot determine the needed set up front, grant a tightly scoped guess, and leave the iteration visible to the user rather than silently widening.

**Red flags that you're about to violate this:**
- "Action star unblocks the deploy and we'll scope it down post-launch..."
- "I keep hitting new AccessDenied errors, broad permissions end the whack-a-mole..."
- "It's a dev account, over-permissioning there is harmless..."
- "AdministratorAccess is what the tutorial attaches..."
- "The service is internal, nothing malicious will ever run as it..."
- "Scoping ARNs is brittle, names might change later..."
