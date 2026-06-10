---
title: Never Let Terraform Replace Stateful Resources
slug: no-replacing-stateful-infra-resources
category: devops
tags: [universal, devops, terraform]
works_with: all
severity: critical
one_liner: "Applying a change that forces replacement of a database or volume"
---

# Never Let Terraform Replace Stateful Resources

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from treating "forces replacement" on a data-bearing resource as an acceptable implementation detail.

**[Copy-paste ready version](../../install/no-replacing-stateful-infra-resources.md)** — just the instruction block, no explanation.

## The Problem

Plenty of innocent-looking attribute edits are immutable in the provider's eyes. Change `identifier` on an `aws_db_instance`, `availability_zone` on an `aws_ebs_volume`, `name` on an `aws_elasticache_cluster`, or `engine_version` across a major boundary, and the plan comes back with `-/+ destroy and then create replacement`. For a stateless web server that's a non-event. For a database, a volume, a queue with messages in it, or a Kafka cluster, "replacement" is a euphemism for "delete all the data and start over."

AI assistants frequently see the `forces replacement` annotation, understand it mechanically, and proceed anyway — narrating it as "Terraform will recreate the resource with the new settings," as if recreation were a feature. The plan was technically reviewed. The data still dies. The missing step isn't reading the plan; it's recognizing that for stateful resources, replacement is a data migration that nobody planned.

The trap is sharpest when the user's request is reasonable ("rename the RDS identifier to match our convention") and the only correct answer is "that attribute change destroys the instance; here's what it would actually take."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Let Terraform Replace Stateful Resources

NEVER apply a plan in which a stateful resource is marked `forces replacement` or `-/+`. Stateful means it holds data or identity that doesn't live in the config: databases (RDS, ElastiCache, DynamoDB), volumes and disks, S3 buckets, message queues, Elastic IPs, KMS keys, certificates, and anything with "cluster" in the name.

Replacement of a stateful resource is not an update. It is delete-everything followed by create-empty, and Terraform will not warn you beyond that one annotation.

- Before editing an attribute on a stateful resource, check whether the provider treats it as immutable (the docs mark these "forces new resource"). If it does, stop and tell the user what replacement would destroy.
- Present alternatives instead of applying: snapshot-and-restore, blue/green with data migration, `create_before_destroy` where the resource type genuinely supports it, or simply not making the cosmetic change.
- If replacement is truly intended, require the user to confirm after you have stated, in plain words, exactly what data ceases to exist and what the restore plan is.
- Verify backups exist and are recent before any approved replacement: `aws rds describe-db-snapshots`, volume snapshots, bucket versioning status.
- Never add `lifecycle { create_before_destroy }` as a magic fix for databases; two instances cannot share an identifier, and the create simply fails after the destroy is already queued.

**Red flags that you're about to violate this:**

- "Terraform will recreate it with the new settings, that's how Terraform works..."
- "It forces replacement, but the config will end up matching what they asked for..."
- "There's probably an automated backup somewhere..."
- "The user approved the plan, even if I didn't spell out the data loss..."
- "It's a small instance, recreating it should be quick..."

---

## Why It Works

1. **It separates "plan reviewed" from "consequence understood."** The AI can quote `forces replacement` verbatim and still not register data loss. The rule makes the data, not the resource, the unit of concern.

2. **It enumerates stateful types.** "Stateful" is exactly the kind of judgment call AIs fumble; a concrete list (databases, volumes, buckets, queues, EIPs, keys) removes the judgment.

3. **It demands a stated restore plan before consent counts.** Approval of a plan summary is not approval of data loss; requiring the plain-words sentence makes the user's confirmation informed.

4. **It pre-blocks the create_before_destroy non-fix.** That lifecycle block is the AI's favorite incantation here, and for identity-bearing resources it makes things worse, not better.

## Origin

An engineer asked for RDS instance identifiers to be standardized to a new naming convention across environments. The assistant edited `identifier` on six instances and applied; `identifier` forces replacement, so all six databases were destroyed and recreated empty. Five had recent automated snapshots. The sixth was a reporting database with snapshots disabled "to save cost," and three years of aggregates were rebuilt from raw events over the following week.
