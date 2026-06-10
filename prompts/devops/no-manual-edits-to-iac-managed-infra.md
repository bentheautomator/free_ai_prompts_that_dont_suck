---
title: No Manual Edits to IaC-Managed Infrastructure
slug: no-manual-edits-to-iac-managed-infra
category: devops
tags: [universal, devops, terraform]
works_with: all
severity: critical
one_liner: "Fixing prod by console or CLI while Terraform still believes the old config"
---

# No Manual Edits to IaC-Managed Infrastructure

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from hotfixing live infrastructure out-of-band, planting a drift bomb that the next apply detonates.

**[Copy-paste ready version](../../install/no-manual-edits-to-iac-managed-infra.md)** — just the instruction block, no explanation.

## The Problem

The AWS CLI is faster than the Terraform workflow, and AI assistants know it. Asked to "increase the ASG max to 20" or "open port 8443 on that security group," an assistant with cloud credentials will often just do it — `aws autoscaling update-auto-scaling-group`, `aws ec2 authorize-security-group-ingress` — because that's the shortest path from request to confirmation. If the resource is managed by Terraform or CloudFormation, the fix is now drift: reality says one thing, code says another, and the disagreement is invisible until someone runs the next plan.

Then the trap springs on a victim who didn't set it. Weeks later, a colleague applies an unrelated change, and Terraform — faithfully converging reality toward code — reverts the manual fix as a side effect. The ASG max snaps back down during a traffic spike; the firewall rule disappears mid-integration. The plan output did show the reversion, buried among legitimate changes, labeled as an update nobody connected to a console fix from three weeks ago.

The manual edit isn't just a process foul; it's a delayed-action change to production, scheduled for "whenever someone next applies," targeted at "whoever that is."

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Manual Edits to IaC-Managed Infrastructure

NEVER modify infrastructure with the console, raw cloud CLI, or SDK calls when that resource is managed by IaC (Terraform, CloudFormation, Pulumi). Out-of-band edits create drift, and the next `apply` silently reverts them — turning your quick fix into a future outage with someone else's name on the apply.

- Before mutating any cloud resource directly, check whether it's IaC-managed: search the repo for its name/ID, run `terraform state list | grep <name>`, or check the resource's tags (many teams tag `ManagedBy: terraform`). Assume managed until proven otherwise.
- Make the change in code, plan, review, apply. Yes, even for one attribute. The IaC path is the change; the CLI path is drift.
- In a genuine emergency where the out-of-band fix must happen first, do the fix and immediately update the IaC to match in the same session — then run `terraform plan` and confirm it shows no diff on that resource. An emergency fix without the follow-up commit is an unexploded reversion.
- Never "fix" drift you discover by adjusting reality to match code without asking — the manual change you're about to revert may be someone's emergency fix that was never backported. Surface the drift, ask which side is right.
- Read-only CLI calls (`describe-*`, `get-*`, `list-*`) are always fine and encouraged for diagnosis.

**Red flags that you're about to violate this:**

- "One CLI call now versus a whole plan-review-apply cycle..."
- "I'll update the Terraform to match later..."
- "It's a tiny attribute change, drift this small won't hurt..."
- "The console is right there and the user wants this fixed now..."
- "The plan shows an unexpected change, I'll just apply and let it converge..."

---

## Why It Works

1. **It gives drift a victim and a fuse.** "Drift" sounds like an accounting discrepancy; "the next apply reverts your fix during someone else's deploy" names the actual failure, which is what makes the shortcut stop looking cheap.

2. **It makes managed-ness a checkable precondition.** The AI usually doesn't know whether a resource is IaC-managed and doesn't ask; a thirty-second `state list` or tag check converts the unknown into a fact before any mutation.

3. **It handles the emergency path realistically.** A flat ban breaks the first time prod is on fire; the backport-in-same-session rule keeps the discipline while admitting that reality sometimes goes first.

4. **It protects the reverse direction too.** Drift the AI finds is often someone's un-backported emergency fix; requiring a human call on which side wins prevents helpfully converging away a load-bearing change.

## Origin

During a traffic surge, an assistant raised an autoscaling group's max capacity from 10 to 24 via the CLI — exactly what was needed, and it worked. The Terraform file kept saying 10. Nineteen days later a routine apply for a tagging change converged the ASG back to max 10, mid-afternoon, mid-spike; the group shed fourteen instances in minutes and the site browned out. The engineer who ran the apply spent an hour convinced the tagging change was somehow at fault, because that was the only thing anyone knew had changed.
