### No IAM Wildcards to Unblock a Deploy

NEVER fix a permission error by granting `Action: "*"`, service-level wildcards (`s3:*`, `iam:*`), or `Resource: "*"`. An AccessDenied names the exact action and resource that were denied; the fix is exactly that grant, scoped to exactly that resource.

- Read the error: it contains the principal, the action (`s3:PutObject`), and usually the ARN. Grant that action on that ARN (or a tight prefix like `arn:aws:s3:::deploy-artifacts/*`), nothing wider.
- Permission errors arriving one at a time is normal. Iterating three times on narrow grants beats one wildcard; if iteration is impractical, derive the needed set from the service's documented actions for the operation, or from CloudTrail/IAM Access Analyzer data on what the role actually calls — then grant that list.
- Treat certain actions as red-line, never granted as collateral: `iam:*` (privilege escalation), `iam:PassRole` un-scoped, `kms:*`, `sts:AssumeRole` on `*`, and any `Delete*`/`Put*Policy` the workflow doesn't demonstrably perform.
- Never widen a *different* principal's policy because it's the one you can edit; fix the principal that was denied.
- If a wildcard already exists in the policy you're editing, don't extend the pattern ("the role already has `s3:*`, so `dynamodb:*` is consistent"). Flag it instead.
- A temporary wildcard "to confirm permissions are the issue" counts as a violation the moment it's applied to a shared environment; use the IAM policy simulator for that experiment instead.

**Red flags that you're about to violate this:**

- "I keep hitting new AccessDenied errors, a wildcard ends the loop..."
- "I can't enumerate everything the deploy will need..."
- "It's only the staging role..."
- "s3:* on one bucket's resources is basically scoped..."
- "The role next to it already has admin, this is no worse..."
