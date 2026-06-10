---
title: Gate Production Deploys Behind Environments
slug: gate-production-deploys-behind-environments
category: ci-cd
tags: [universal, ci, deploy]
works_with: all
severity: critical
one_liner: "Stops the AI from wiring deploy steps that ship to prod with no approval gate"
---

# Gate Production Deploys Behind Environments

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding production deploy steps that fire automatically on merge with no environment protection, approval, or gate in between.

**[Copy-paste ready version](../../install/gate-production-deploys-behind-environments.md)** — just the instruction block, no explanation.

## The Problem

The shortest way to "add a deploy step" is a job that runs `deploy.sh prod` whenever main gets a push. No `environment:` declaration, no required reviewers, no concurrency control, no distinction between "this commit passed CI" and "a human decided this commit should be in production right now." Every merge is now a production deployment, including the Friday 5:55 p.m. one, the dependabot one, and the one where someone merged the wrong PR.

CI platforms all have a primitive for this — GitHub `environment:` with protection rules, GitLab protected environments, manual approval stages — and the entire point of the primitive is that the deploy job inherits its gates and its scoped secrets from configuration that lives outside the YAML. A deploy step without it gets neither: any branch that can run the workflow can reach the prod credentials, and nothing stands between a green test suite and live traffic.

Assistants skip the gate because it's invisible in examples (protection rules are repo settings, not YAML, so copied workflows never carry them) and because an ungated pipeline demos better — the assistant can show the whole flow working end to end. "It deploys automatically!" is presented as the feature. For production, it's the incident.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Gate Production Deploys Behind Environments

NEVER create a pipeline step that deploys to production without binding it to a protected environment with an approval gate. A merge means the code passed its checks; it does not mean anyone decided to ship it.

- Every deploy job must declare its target: `environment: production` (GitHub), a protected environment (GitLab), a manual-approval stage (Jenkins/CircleCI/Azure). Production credentials must live as environment-scoped secrets, retrievable only by jobs bound to that environment — never as repo-wide secrets a feature branch workflow can read.
- When you add the `environment:` binding, tell the user which protection rules to enable in repo settings (required reviewers, deployment branch restriction to the default branch), because those rules are settings, not YAML, and the YAML alone gates nothing.
- Auto-deploy on merge is fine for preview and staging environments. The promotion from staging to production is where a human approval belongs.
- Add `concurrency:` to the deploy job so two merges can't deploy to the same environment simultaneously or out of order.
- If the user explicitly wants continuous deployment to production with no manual gate, implement it only after confirming that's the intent, and pair it with the compensating controls that make CD sane: deployment branch restrictions, concurrency control, and a documented rollback step in the same workflow.
- Never remove or weaken an existing environment gate to "unblock" a deployment. A gate someone is waiting at is functioning, not malfunctioning.

**Red flags that you're about to violate this:**

- "Deploying on every merge is just continuous deployment; that's best practice."
- "The approval step makes the demo clunky."
- "It's a small team; everyone who can merge is allowed to deploy anyway."
- "The environment setting is just a label; I'll skip configuring it."
- "The release is urgent and the approval gate is what's blocking it."

---

## Why It Works

1. **It separates two events the pipeline otherwise fuses**: "the code is verified" and "someone chose to ship it." Merging encodes the first; only a gate encodes the second.
2. **It moves prod credentials behind the gate, not just the job** — environment-scoped secrets mean even a malicious or buggy workflow on a branch can't reach prod keys, which is the part of the protection that YAML-copying loses.
3. **It makes the assistant surface the settings-side half.** The most common failure is YAML that *names* an environment nobody protected; requiring the instruction to the user closes the gap between looking gated and being gated.
4. **It permits real CD only as an explicit, compensated decision**, so the rule can be strict by default without fighting teams that genuinely ship on every merge.

## Origin

A repo's deploy workflow ran on every push to main with prod credentials in repo-level secrets. A contractor merged a branch that was meant for a fork, CI passed because the code compiled, and the deploy job shipped a half-finished payment flow to production at lunchtime — no human had decided to release anything. The postmortem's first finding was that the deployment system had no concept of a decision: the word "deploy" appeared in the YAML eleven times and the word "approve" zero.
