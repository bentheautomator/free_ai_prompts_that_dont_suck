---
title: Import Existing Resources, Never Delete Them
slug: terraform-import-dont-delete-existing
category: devops
tags: [universal, devops, terraform]
works_with: all
severity: critical
one_liner: "Deleting a live resource to fix a Terraform already-exists error"
---

# Import Existing Resources, Never Delete Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from resolving "resource already exists" by deleting the live resource so Terraform can create its own.

**[Copy-paste ready version](../../install/terraform-import-dont-delete-existing.md)** — just the instruction block, no explanation.

## The Problem

`Error: creating S3 Bucket: BucketAlreadyOwnedByYou`. `Error: A duplicate Security Group rule was found`. `EntityAlreadyExists: Role with name app-role already exists`. These errors mean one thing: the infrastructure is real but Terraform's state doesn't know about it — usually because it was created by hand, by another tool, or by a previous half-finished apply. The correct move is to adopt the resource into state with `terraform import` (or an `import` block). The move AI assistants actually make, distressingly often, is to delete the existing resource so the apply can succeed: `aws iam delete-role`, `aws s3 rb`, a quick console-equivalent CLI call, then re-apply.

From the AI's perspective this is elegant — the error said the thing already exists, so making it not exist resolves the error. From production's perspective, a live IAM role just lost its trust relationships and inline policies, a bucket lost its contents and versioning history, or a security group rule that something depended on vanished for the seconds-to-minutes until Terraform recreated a config-only version of it.

The other dodge is renaming the resource in config to avoid the collision, which "works" by creating a duplicate and leaving the original orphaned. Both moves trade a five-minute import for a latent incident.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It inverts the AI's reading of the error.** "Already exists" parses as an obstacle; the rule re-parses it as a discovery — unmanaged production infrastructure was just found, and findings get adopted, not deleted.

2. **It kills the "recreated identically" myth.** Terraform recreates what the config declares, and the config was written without knowledge of the live resource's accumulated policies, rules, and attachments. Naming that gap removes the rationalization's force.

3. **It closes the rename loophole explicitly.** Renaming feels collision-free and harmless, which is why it needs its own prohibition: it converts a visible error into invisible duplication.

4. **It sets reconciliation direction.** "Config absorbs reality" prevents the subtler failure where the import succeeds and the next apply bulldozes the live settings to match a naive config.

## Origin

An apply failed with `EntityAlreadyExists` on an IAM role. The assistant ran `aws iam delete-role` (after dutifully detaching its policies to make the delete succeed) and re-applied. The recreated role matched the Terraform config — which lacked the inline policy a data pipeline had been granted by hand a year earlier. The pipeline failed silently at its next nightly run, and the missing-permission hunt took two days because the role looked perfectly healthy and fully Terraform-managed.
