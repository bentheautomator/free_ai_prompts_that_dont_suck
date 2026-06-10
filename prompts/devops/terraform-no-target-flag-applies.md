---
title: No Targeted Terraform Applies
slug: terraform-no-target-flag-applies
category: devops
tags: [universal, devops, terraform]
works_with: all
severity: high
one_liner: "Using -target to force partial applies that leave state half-updated"
---

# No Targeted Terraform Applies

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from using `-target` and `-replace` as a crowbar to push one resource through while the rest of the plan rots.

**[Copy-paste ready version](../../install/terraform-no-target-flag-applies.md)** — just the instruction block, no explanation.

## The Problem

When a full `terraform plan` shows changes the AI doesn't understand or an apply fails partway, `-target=aws_lambda_function.api` looks like precision: apply just the thing the user asked about, ignore the noise. Terraform itself prints a warning that targeted applies are for exceptional circumstances, and the AI scrolls past it. What `-target` actually does is apply one slice of a dependency graph while deliberately not applying the rest — leaving state where some resources reflect the new config, others the old, and the next person to run a full plan inherits a diff they didn't write and can't explain.

It gets worse when the AI chains the habit: each confusing plan gets another targeted apply, and the gap between config and reality compounds. `-replace` (and the deprecated `taint`) gets abused the same way — forcing recreation of a resource to clear an error without understanding why the resource was unhealthy, which is rebooting-but-for-infrastructure.

Assistants do this because the unexplained parts of a plan feel like someone else's problem, and `-target` lets them ship the requested change without confronting the rest. The unexplained diff is precisely the part that needed attention.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Targeted Terraform Applies

NEVER use `terraform apply -target=...` or `-replace=...` to work around a confusing plan, a failed apply, or changes you didn't expect. Targeted applies split the dependency graph and leave state partially updated; the unexplained remainder of the plan is debt assigned to whoever runs Terraform next.

- If a full plan contains changes beyond what the user asked for, that is information, not noise: report the unexpected diff and find out why (drift, someone else's unapplied work, a provider upgrade) before applying anything.
- If an apply fails partway, run a fresh full plan and fix the cause of the failure. Terraform is designed to converge from partial applies; `-target` is not the convergence mechanism.
- Do not use `-replace` to "refresh" an unhealthy resource without first diagnosing why it's unhealthy. Recreating it usually recreates the problem, minus the evidence.
- Legitimate `-target` uses exist (bootstrapping circular dependencies, emergency isolation of a broken module) but they are the user's call: name the flag, the target, and why a full apply won't work, then wait.
- After any targeted apply the user does approve, run a full `terraform plan` immediately and report what remains unapplied, so the partial state is documented rather than discovered.

**Red flags that you're about to violate this:**

- "The full plan has a bunch of unrelated changes, I'll just target the one resource I touched..."
- "Terraform warns about -target but it's only a warning..."
- "The apply failed halfway, targeting the failed resource will finish the job..."
- "I'll replace the instance to clear the weird error state..."
- "Someone else's pending changes aren't my problem to apply..."

---

## Why It Works

1. **It reclassifies "unrelated changes" as a finding.** The AI's instinct is to filter the plan down to its own diff; the rule defines the unexpected remainder as the thing that must be reported, which is the opposite of targeting around it.

2. **It blocks the failure-recovery misuse.** Partial-apply recovery is the single most common `-target` rationalization, and Terraform's actual recovery mechanism (re-plan, re-apply) is named so there's no vacuum.

3. **It separates legitimate use from convenience use.** Bootstrapping cycles is real; routing it through explicit user approval lets the rule stay absolute in daily work without being wrong.

4. **It forces documentation of any approved partial state.** A follow-up full plan turns "mystery diff next week" into "known remainder today."

## Origin

A platform team noticed their weekly drift-check plan had ballooned to 60 pending changes. Archaeology showed an assistant had spent two months applying every request with `-target`, each time stepping around a growing pile of unapplied changes that began with one harmless provider-upgrade diff it didn't want to deal with. Untangling which of the 60 changes were intentional took two engineers most of a sprint, during which all other infra work was frozen.
