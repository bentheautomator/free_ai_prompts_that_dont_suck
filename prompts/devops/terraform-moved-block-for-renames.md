---
title: Use Moved Blocks for Terraform Renames
slug: terraform-moved-block-for-renames
category: devops
tags: [universal, devops, terraform]
works_with: all
severity: critical
one_liner: "Renaming a Terraform resource address, which destroys and recreates it"
---

# Use Moved Blocks for Terraform Renames

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "tidying up" a Terraform resource name and accidentally scheduling the real resource for destruction.

**[Copy-paste ready version](../../install/terraform-moved-block-for-renames.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to clean up a Terraform module — better names, consistent prefixes, move resources into a module — and it will happily rename `aws_db_instance.db` to `aws_db_instance.main`. In source code, a rename is a refactor. In Terraform, the resource address is the identity. State still holds `aws_db_instance.db`, the config now declares `aws_db_instance.main`, and Terraform concludes the old resource should be destroyed and a new one created. Your production database just became a line item under "Plan: 1 to add, 0 to change, 1 to destroy."

AI assistants fall into this because renaming identifiers is one of the safest operations in ordinary programming, and they carry that intuition straight into `.tf` files. They also frequently do the rename as part of a bigger refactor, so the destroy hides inside a large diff that looks like pure reorganization.

Terraform has a first-class fix — the `moved` block — that tells the planner "this is the same resource at a new address." The AI just doesn't reach for it unless told, because nothing about the rename looks dangerous.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use Moved Blocks for Terraform Renames

NEVER rename a Terraform resource, move it into or out of a module, or change `count` to `for_each` without a `moved` block (or an explicit `terraform state mv`, with user approval). A resource's address is its identity: change the address without telling Terraform, and the plan becomes destroy-old plus create-new.

- For every rename or module move, add a `moved` block in the same change: `moved { from = aws_db_instance.db, to = aws_db_instance.main }`.
- This applies to module restructuring too: moving `aws_s3_bucket.logs` into `module.storage` changes its address to `module.storage.aws_s3_bucket.logs` and needs a `moved` block.
- Converting `count` to `for_each` changes every instance address (`[0]` becomes `["key"]`); write a `moved` block per instance.
- After the change, run `terraform plan` and verify it reports the move (or zero changes), not a destroy/create pair. A plan containing `destroy` for a resource you only renamed means the move is wired wrong. Stop.
- On older Terraform without `moved` blocks, propose `terraform state mv` commands for the user to review and run; do not run them unprompted.
- Pure cosmetic renames of stateful resources (databases, volumes, buckets, queues) are not worth doing at all unless the user explicitly wants them. Say so.

**Red flags that you're about to violate this:**

- "This is just a rename, refactors don't change behavior..."
- "The new name is more consistent with the rest of the module..."
- "I'm only moving it into a module, the resource block itself is identical..."
- "Terraform will figure out it's the same resource..."
- "The plan shows one add and one destroy, which is what a rename looks like..."
- "I'll skip the moved block, state mv can fix it later if anyone notices..."

---

## Why It Works

1. **It reframes the address as identity, not a label.** The AI's refactoring instinct assumes names are decoration. Stating that the address is how Terraform matches config to real infrastructure removes the false analogy with code refactoring.

2. **It makes the verification concrete.** "Plan must show a move, not a destroy/create pair" is a binary check the AI can perform, instead of relying on the rename "feeling safe."

3. **It covers the non-obvious cases.** Module moves and `count`-to-`for_each` conversions don't look like renames at all, so they're listed explicitly rather than left to inference.

4. **It questions the rename itself.** Often the right answer is to leave the ugly name alone, and the rule gives the AI permission to say that.

## Origin

A team asked their assistant to reorganize a flat Terraform root module into logical sub-modules. The AI produced a beautiful structure, and the plan — skimmed quickly because "it's just a refactor" — destroyed and recreated 40 resources, including an ElastiCache cluster whose recreation dropped every session in the application. The same restructure with `moved` blocks would have been a zero-change plan.
