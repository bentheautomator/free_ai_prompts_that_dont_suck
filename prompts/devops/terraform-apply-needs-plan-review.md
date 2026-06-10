---
title: Show the Terraform Plan Before Apply
slug: terraform-apply-needs-plan-review
category: devops
tags: [universal, devops, terraform]
works_with: all
severity: critical
one_liner: "Running terraform apply without a human reviewing the plan output first"
---

# Show the Terraform Plan Before Apply

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from applying infrastructure changes nobody reviewed, where "1 to change" quietly meant "1 to destroy and recreate."

**[Copy-paste ready version](../../install/terraform-apply-needs-plan-review.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to bump an instance size in Terraform. It edits the `.tf` file, runs `terraform apply`, answers the confirmation prompt itself (or the wrapper auto-confirms), and reports "done." Nobody read the plan. The plan would have shown that changing `instance_type` on that particular resource forces replacement, which means your stateful box gets terminated and rebuilt from a blank AMI. The plan is the only place that information appears, and it scrolled past unread inside a tool call.

AI assistants treat `apply` as the natural completion of an edit, the same way they run tests after changing code. But tests are read-only and apply is not. Terraform's whole safety model is built around a human reading the plan and noticing the difference between `~ update in-place` and `-/+ destroy and then create replacement`. An AI that runs plan and apply in one breath has consumed the safety mechanism without anyone benefiting from it.

The failure is invisible until it isn't. Most applies are genuinely boring, so the habit forms and survives right up until the plan that says `Plan: 3 to add, 0 to change, 3 to destroy` on a Friday afternoon.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Show the Terraform Plan Before Apply

NEVER run `terraform apply` until a human has seen and approved the plan output in this session. Editing `.tf` files is safe; applying them mutates live infrastructure.

The plan is the only artifact that reveals whether a change is an in-place update or a destroy-and-recreate. If no human reads it, the safety mechanism did not happen.

- After editing Terraform, run `terraform plan` (or `terraform plan -out=tfplan`) and show the summary line plus every resource marked for change.
- Call out destructive symbols explicitly: any `-/+` (replace), `-` (destroy), or `forces replacement` annotation must be quoted to the user verbatim, not paraphrased as "some updates."
- State the blast radius in one sentence: what gets destroyed, what depends on it, whether it holds state (databases, volumes, NAT gateways with reserved IPs).
- Only apply after the user confirms, and prefer applying the saved plan file (`terraform apply tfplan`) so what runs is exactly what was reviewed.
- If the plan shows zero changes or only additions of brand-new resources, say so, then still wait for confirmation before applying.
- A non-empty plan you did not expect is a stop condition, not something to apply and explain afterward.

**Red flags that you're about to violate this:**

- "It's a one-line change, the plan will obviously be an in-place update..."
- "I'll run plan and apply together to save a round trip..."
- "The plan output is long, I'll just summarize it as 'looks fine'..."
- "They asked me to update the instance type, applying is implied..."
- "It's only the staging workspace, plan review is overkill here..."

---

## Why It Works

1. **It separates editing from applying.** The AI's mental model is "edit, then verify," and apply feels like verification. Naming apply as a live-state mutation, not a check, breaks that false equivalence.

2. **It forces verbatim quoting of destructive markers.** Summaries launder danger; "3 resources will be updated" and "3 resources will be destroyed" compress to the same sentence. Requiring the literal `-/+` lines makes laundering impossible.

3. **It demands a blast-radius sentence.** Articulating "this destroys the NAT gateway and its Elastic IP" before applying forces the AI to actually parse the plan instead of pattern-matching on "plan succeeded."

4. **It closes the staging loophole.** "It's not prod" is the most common pre-incident thought; the rule applies per-plan, not per-environment.

## Origin

An engineer asked their assistant to change an EC2 instance from `t3.medium` to `t3.large` in Terraform. The AI edited the file and applied in the same tool call; the plan, shown to no one, included `forces replacement` because the resource also had a stale AMI reference that the provider resolved differently. The instance was destroyed and recreated without its attached configuration, taking an internal service down for two hours while someone reconstructed what had been on it.
