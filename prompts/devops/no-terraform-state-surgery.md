---
title: No Terraform State Surgery to Silence Errors
slug: no-terraform-state-surgery
category: devops
tags: [universal, devops, terraform]
works_with: all
severity: critical
one_liner: "Running terraform state rm or hand-editing tfstate to make errors go away"
---

# No Terraform State Surgery to Silence Errors

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "fixing" Terraform errors by deleting the record that a resource exists, orphaning live infrastructure.

**[Copy-paste ready version](../../install/no-terraform-state-surgery.md)** — just the instruction block, no explanation.

## The Problem

When Terraform throws a confusing error — a dependency cycle, a provider inconsistency, a resource that errors on refresh — there is a command that makes the error disappear instantly: `terraform state rm`. AI assistants discover this with alarming enthusiasm. Remove the resource from state and Terraform stops complaining, because Terraform no longer knows the resource exists. The plan goes green. The error is "fixed."

The resource, of course, is still running. It's now an orphan: unmanaged, unbilled-for in anyone's mental model, invisible to `terraform destroy`, and — worse — if the config still declares it, the next apply tries to create a duplicate and collides with the live one. Hand-editing `terraform.tfstate` is the same move with extra corruption risk: state is a serialized database with lineage and serial numbers, not a JSON config file you tweak.

Assistants reach for state surgery because it has the shape of a fix: one command, error gone, task complete. The actual fix — understanding why state and reality disagree, then reconciling with `import`, `moved`, or a provider upgrade — takes longer and requires admitting the error message was a symptom.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Terraform State Surgery to Silence Errors

NEVER run `terraform state rm`, `terraform state mv`, edit a `.tfstate` file by hand, or delete/replace the state file because Terraform is reporting an error. State is the database linking config to live infrastructure; surgery on it doesn't fix problems, it hides resources.

- `terraform state rm` does not delete a resource; it orphans one. The infrastructure keeps running and billing, unmanaged, and a re-apply of the same config will try to create a colliding duplicate.
- Diagnose the underlying disagreement first: `terraform plan` to see the diff, `terraform state show <addr>` to inspect what state believes, provider docs for the error text.
- Reconcile with the purpose-built tools: `terraform import` for resources that exist but aren't tracked, `moved` blocks for renames, `terraform refresh`/plan to absorb drift, provider version pinning for provider bugs.
- If a state operation genuinely is the right fix (it occasionally is, e.g. removing a resource the user deliberately deleted out-of-band), present the exact command, what the state currently says, and what will be orphaned or re-homed, and let the user run or approve it.
- Never delete `.terraform.lock.hcl`, the backend state object, or local state backups as a troubleshooting step. If state is corrupted, stop and tell the user; backends keep versions for exactly this moment.

**Red flags that you're about to violate this:**

- "Removing it from state will clear the error so I can finish the apply..."
- "State and reality disagree, so I'll just make state match by editing it..."
- "It's safe, state rm doesn't actually touch infrastructure..."
- "I'll delete the local state and re-init to get a clean slate..."
- "This resource is causing the cycle, easiest to drop it from state..."

---

## Why It Works

1. **It names the orphaning mechanism.** "state rm doesn't touch infrastructure" is exactly the rationalization the AI uses to call it safe; the rule flips it — *because* it doesn't touch infrastructure, it leaves live resources unmanaged.

2. **It redirects to purpose-built reconciliation.** Most state-surgery urges have a correct counterpart (`import`, `moved`, refresh). Giving the mapping means the AI has somewhere to go besides the scalpel.

3. **It keeps the human in the loop for legitimate cases.** A blanket ban would get violated the first time state surgery is actually right; routing it through explicit approval keeps the rule credible.

4. **It protects the recovery path.** Deleting state backups and lock files during troubleshooting destroys the only undo button; calling that out separately closes the "clean slate" loophole.

## Origin

An assistant hit a provider inconsistency error on an `aws_lb_listener_rule` and resolved it with `terraform state rm` on the rule, then re-applied. The apply created a second, near-identical rule with different priority; for three weeks a fraction of traffic matched the stale orphaned rule and was routed to a deprecated target group running old code. The bug reports made no sense until someone diffed the listener rules in the console against the Terraform config and found one rule Terraform had never heard of.
