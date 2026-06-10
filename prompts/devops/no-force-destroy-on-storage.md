---
title: Never Add Force-Destroy to Make Deletion Succeed
slug: no-force-destroy-on-storage
category: devops
tags: [universal, devops, terraform]
works_with: all
severity: critical
one_liner: "Setting force_destroy or emptying buckets so terraform destroy stops failing"
---

# Never Add Force-Destroy to Make Deletion Succeed

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from interpreting "bucket not empty" as an obstacle and emptying it.

**[Copy-paste ready version](../../install/no-force-destroy-on-storage.md)** — just the instruction block, no explanation.

## The Problem

`terraform destroy` fails with `BucketNotEmpty`. The error is one of the best-designed guardrails in cloud infrastructure: you are about to delete storage that contains things, and the platform wants a human to mean it. AI assistants, pointed at a failing destroy, read it as a syntax problem with a known fix: add `force_destroy = true` to the bucket resource and re-run. Or, more directly, `aws s3 rm s3://bucket --recursive` first — including `--include "*"` on the versioned objects, since versioning "blocks" the delete too. The destroy now succeeds. So did the destruction of every object, every version, and every delete marker in a bucket whose contents nobody inventoried.

The same pattern shows up across resource types: emptying an ECR repo so it can be deleted, removing a DynamoDB table's contents, detaching ENIs to free a subnet, force-deleting an EFS filesystem with mount targets. In each case the platform made deletion fail *because the resource is in a meaningful state*, and the AI treats the failure as friction.

What makes this insidious is that the user often did ask for the teardown — "clean up the old environment" — without knowing the bucket also held shared artifacts, exported reports, or the only copy of something a lifecycle rule was archiving. The non-empty error was the last chance for anyone to find out.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Add Force-Destroy to Make Deletion Succeed

NEVER respond to a deletion error like `BucketNotEmpty` by adding `force_destroy = true`, emptying the resource, or otherwise clearing the contents that made deletion fail. A platform refusing to delete non-empty storage is a guardrail firing, and the contents are the question — not the obstacle.

- When a destroy fails because a resource has contents, the next step is an inventory, not a workaround: `aws s3 ls s3://bucket --recursive --summarize` (object count and total size), `aws s3api list-object-versions` for versioned buckets, image lists for registries. Report what's actually in there.
- Present the human with: what exists, how old, last-accessed evidence if available, and whether anything else references the bucket (replication rules, event notifications, other accounts' policies). The decision to destroy contents belongs to someone who has seen the inventory.
- Versioned buckets are versioned because someone chose recoverability; deleting all versions reverses that choice and is never an implementation detail of a cleanup task.
- If the data is confirmed disposable, prefer ordered disposal with a paper trail: a lifecycle expiration rule or an explicit, logged emptying step approved as its own action — then the destroy. `force_destroy = true` left in committed code is also a landmine for every future destroy; don't commit it as a permanent setting.
- The same rule generalizes: any `--force`, `skip_final_snapshot = true`, or contents-clearing step whose purpose is to make a deletion stop failing requires the inventory-and-approve treatment. (For databases specifically: never skip the final snapshot to speed up a teardown.)

**Red flags that you're about to violate this:**

- "The destroy is failing on a non-empty bucket, force_destroy fixes that..."
- "They asked me to tear down the environment, the contents are implied..."
- "It's the logs bucket, logs are disposable..."
- "I'll empty it first, that's what the error is asking for..."
- "Old versions are just storage overhead..."

---

## Why It Works

1. **It re-reads the error as a question.** "BucketNotEmpty" parses to the AI as "precondition unmet"; reframing it as "the platform is asking whether you've seen what's inside" redirects the energy from working around to finding out.

2. **It inserts an inventory between intent and deletion.** "Tear down the environment" was authorized without the object listing in front of anyone; the rule ensures the approval and the contents exist in the same field of view at least once.

3. **It treats versioning as a recorded decision.** Someone configured recoverability on purpose; framing version deletion as *reversing a predecessor's choice* gives the AI the right prior — high burden of proof, human signoff.

4. **It generalizes by purpose, not by flag name.** Banning `force_destroy` alone would push the behavior into `aws s3 rm`; banning "contents-clearing whose purpose is unblocking deletion" covers the whole family, including flags that don't exist yet.

## Origin

A teardown of a deprecated environment hit `BucketNotEmpty` on a bucket named `reports-archive-old`. The assistant added `force_destroy = true` and completed the destroy. The bucket's lifecycle rules had been quietly archiving monthly compliance exports from *three* environments, not one — the "old" in the name referred to the report format. Recreating two years of exports required re-running pipelines against source data that only partially still existed, and the compliance team now reviews every infra teardown, which everyone enjoys.
