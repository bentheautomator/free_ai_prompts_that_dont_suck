---
title: Never Delete Unused Cloud Resources on a Hunch
slug: never-delete-unused-cloud-resources
category: devops
tags: [universal, devops]
works_with: all
severity: critical
one_liner: "Deleting cloud resources because nothing visible references them"
---

# Never Delete Unused Cloud Resources on a Hunch

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting the security group, bucket, or IAM role that "nothing uses" — except the thing that breaks at 3 a.m.

**[Copy-paste ready version](../../install/never-delete-unused-cloud-resources.md)** — just the instruction block, no explanation.

## The Problem

"Unused" is the most expensive word in cloud operations. An AI doing cleanup — or just trying to make an apply succeed — concludes a resource is unused because nothing *it can see* references it: the security group isn't attached to any instance in this account's EC2 list, the bucket has no recent writes, the IAM role doesn't appear in the repo. Then it deletes the resource, and discovers the hard way that cloud reference graphs are not greppable. The security group was referenced by a rule in *another* security group, or by a Lambda in a peered VPC. The bucket was the destination for monthly billing exports and a disaster-recovery replica. The IAM role was assumed cross-account by a partner integration that runs quarterly.

Deletions are also disproportionately permanent. A misconfigured setting reverts; a deleted S3 bucket's name may be unrecoverable, a deleted KMS key makes every object it encrypted permanently unreadable (after a waiting period that exists precisely because people do this), and a deleted log group is evidence gone.

The honest statement is never "this is unused" — it's "I could not find a use," which is a statement about the searcher. The professional alternative is to disable, detach, or quarantine first, and let time prove the negative.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Delete Unused Cloud Resources on a Hunch

NEVER delete a cloud resource because it appears unused. "Nothing references it" means "nothing I checked references it" — cloud dependency graphs span accounts, regions, peered networks, and scheduled jobs that run quarterly.

- Before proposing any deletion, gather actual evidence of disuse: access logs and CloudTrail events over a meaningful window (90+ days for anything that might serve periodic jobs), attachment/reference queries (`aws ec2 describe-network-interfaces --filters Name=group-id,...` for security groups, `InUseBy` for certs, policy attachments for roles), and billing data showing activity.
- Prefer reversible quarantine over deletion: detach the security group, deny-all the IAM role via an attached policy, block public access and lifecycle-archive the bucket, stop (don't terminate) the instance. Wait an agreed period — weeks, not minutes — and delete only after silence.
- Some deletions are categorically not yours to make without explicit human signoff, regardless of evidence: KMS keys, S3 buckets with any objects, log groups, snapshots and backups, DNS zones, and anything with "backup," "audit," or "dr" in the name.
- Never delete a resource as a means to an end — to free a name, silence an error, or make `terraform destroy` complete. That's a deletion smuggled in as a fix.
- Present every proposed deletion with the evidence, the blast radius if you're wrong, and the recovery story (or the words "unrecoverable"). Let a human pull the trigger.

**Red flags that you're about to violate this:**

- "I searched the repo and nothing references this role..."
- "No traffic in the last week, it's clearly dead..."
- "Deleting it cleans up the account and the apply will finally go through..."
- "It's named temp-test-2022, obviously deletable..."
- "If anything used it, surely there'd be an alarm..."

---

## Why It Works

1. **It corrects the epistemics.** Swapping "this is unused" for "I could not find a use" relocates the uncertainty where it belongs — in the search, which was scoped to one account, one region, and one repo.

2. **It substitutes quarantine for deletion.** Detach-and-wait delivers the same cleanup outcome with an undo button; once that option is named, immediate deletion has no remaining advantage except impatience.

3. **It hard-lists the unrecoverables.** KMS keys, backups, and log groups punish mistakes permanently; a categorical human-signoff list means no evidence threshold, however convincing, authorizes the AI alone.

4. **It blocks instrumental deletion.** Half of AI resource deletions aren't cleanup at all — they're a way to clear an error. Naming that pattern separately keeps the rule intact when deletion is a means rather than the goal.

## Origin

A cost-cleanup task identified a security group with no attached instances. The assistant deleted it; the deletion succeeded because the only references were ingress rules *in other security groups* across a VPC peering connection, which don't block deletion — they silently become dangling. A partner data feed in the peered VPC lost connectivity, but only at its next weekly run, five days later, by which point the cleanup PR was merged, forgotten, and three engineers deep into debugging the partner's firewall instead.
