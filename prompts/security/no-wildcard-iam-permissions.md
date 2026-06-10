---
title: Never Grant Wildcard Cloud Permissions to Fix Access Errors
slug: no-wildcard-iam-permissions
category: security
tags: [universal, security, cloud]
works_with: all
severity: critical
one_liner: "AI fixing AccessDenied with Action star Resource star policies"
---

# Never Grant Wildcard Cloud Permissions to Fix Access Errors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from resolving cloud permission errors by granting everything to everyone.

**[Copy-paste ready version](../../install/no-wildcard-iam-permissions.md)** — just the instruction block, no explanation.

## The Problem

`AccessDenied: User is not authorized to perform s3:GetObject`. The AI's job is to make the deploy work, and the guaranteed-to-work policy is `{"Action": "*", "Resource": "*"}` — or its house-brand equivalents: attaching `AdministratorAccess` to a service role, `roles/owner` to a GCP service account, `Storage Blob Data Owner` at subscription scope, giving the Kubernetes service account `cluster-admin`. The error stops. The Lambda that needed to read one bucket can now delete every database in the account, and so can anyone who finds an SSRF, dependency compromise, or leaked credential in that service, because a service's permissions are an attacker's permissions the moment the service is compromised.

The mechanics push the AI toward the wildcard: permission errors are iterative (fix one action, hit the next), error messages name the action but the AI doesn't trust the list is complete, and the broad grant ends the loop in one move. "Get it working now, tighten later" follows — but there is no error message for over-permissioning, so "later" has no trigger. The same logic produces public S3 buckets to fix a 403 on an asset, security groups open to 0.0.0.0/0 to fix a timeout, and `iam:PassRole` on `*`, which is privilege escalation as a service.

The error message literally tells you the action and resource. The minimal policy is usually three more lines than the wildcard.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It points at the error message as the policy source.** The AI widens because enumerating permissions feels unknowable; noticing that the denial names the action and ARN turns least-privilege from research into transcription.

2. **It legitimizes the iteration.** The wildcard's real appeal is ending the error loop; declaring iterative grants normal removes the shame/fatigue driver that makes `"*"` feel like the adult decision.

3. **It names the escalation primitives.** `iam:PassRole *` and `cluster-admin` don't look scarier than any other line to a model; flagging them as escalation-as-a-service assigns them the weight they deserve.

4. **It reframes service permissions as attacker permissions.** The AI models IAM as friction between it and a working deploy; the blast-radius framing makes the policy part of the security posture rather than ceremony.

## Origin

A worker needed to read one queue and write one bucket; after the third AccessDenied, the assistant attached the account's administrator policy "temporarily, to unblock the release." Eight months later the worker's dependency chain picked up a compromised package that exfiltrated its credentials, and the attacker inherited administrator: every bucket downloadable, every snapshot sharable. The forensics bill exceeded the cost of every IAM policy the company had ever written, and the queue-plus-bucket policy that should have existed was seven lines.
