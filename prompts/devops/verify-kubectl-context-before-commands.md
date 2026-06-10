---
title: Verify the Kubectl Context Before Every Mutation
slug: verify-kubectl-context-before-commands
category: devops
tags: [universal, devops, kubernetes]
works_with: all
severity: critical
one_liner: "Running kubectl mutations against whatever cluster was last selected"
---

# Verify the Kubectl Context Before Every Mutation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from scaling, deleting, or applying into production because that's where the kubeconfig happened to be pointing.

**[Copy-paste ready version](../../install/verify-kubectl-context-before-commands.md)** — just the instruction block, no explanation.

## The Problem

`kubectl` has global, sticky, invisible state: the current context. Whatever cluster and namespace the last human (or script, or earlier AI session) switched to is where every subsequent command lands. An AI asked to "delete the test deployment and reapply" runs `kubectl delete deploy api && kubectl apply -f api.yaml` — competent commands, wrong cluster, because someone debugged production an hour ago and the context still says so. The commands don't fail. They succeed, somewhere unintended, and the AI reports success while staging remains unchanged and production briefly has no API deployment.

This failure mode is special because there is no error to catch. Both clusters have a deployment named `api`. Both accept the commands. The only defense is checking *before* acting — and AI assistants essentially never run `kubectl config current-context` unprompted, because nothing in the task mentions contexts. The same trap exists one level down with namespaces: `kubectl delete pod -l app=worker` in the wrong namespace, or with no namespace where the default isn't what the AI assumed.

Identical structure applies to every context-carrying CLI: `aws` profiles and `AWS_PROFILE`, `gcloud config` projects, `az account`, `helm` against the kube context, `flyctl`, `vercel`. Sticky environment state plus an assistant that starts executing from a cold start is a production incident with a countdown.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify the Kubectl Context Before Every Mutation

ALWAYS verify where a cluster-mutating command will land before running it. The kubectl context is sticky, inherited from whoever used the shell last, and silently wrong; a mutation against the wrong cluster usually succeeds.

- Before the first mutating command of a session (and after any long gap), run and report: `kubectl config current-context` and the target namespace. Confirm it matches the environment the task is about, out loud: "context is `staging-eu`, namespace `payments` — proceeding."
- Prefer making the target explicit per-command rather than trusting ambient state: `kubectl --context staging-eu -n payments apply -f ...`. A command that names its target is self-documenting and survives the context changing underneath you.
- The same applies to every environment-sticky CLI: check `aws sts get-caller-identity` / `AWS_PROFILE` before AWS mutations, `gcloud config get-value project`, `az account show`, and pass `--context`/`--kube-context` to helm.
- Escalate verification with blast radius: for anything destructive (delete, scale to zero, rollout restart, drain), restate cluster + namespace + resource in one line and, if the context contains `prod` and the task didn't say prod, stop and ask.
- Never "fix" a wrong-cluster mistake silently. If a mutation may have landed in the wrong place, report it immediately with the exact commands run — the cleanup is time-critical and not yours to improvise alone.
- Read-only commands are exempt; this rule is about mutations.

**Red flags that you're about to violate this:**

- "The user said delete the deployment, the context is whatever it is..."
- "I checked the context earlier in this session..."
- "These are dev-sounding resource names, this must be the dev cluster..."
- "Adding --context to every command is verbose, the default is fine..."
- "kubectl didn't error, so it went where it should..."

---

## Why It Works

1. **It surfaces invisible state at the decision point.** The context is unknowable from the command text, which is why the AI never thinks about it; mandating the check-and-announce makes the hidden variable part of the visible workflow.

2. **It shifts from ambient to explicit addressing.** `--context` per command converts correctness from a property of shell history into a property of the command itself — reviewable, replayable, and immune to whoever uses the terminal next.

3. **It scales scrutiny with damage.** A blanket re-verify on every `get` would be ignored as noise; tying the strict restatement to destructive verbs keeps the rule cheap enough to actually follow.

4. **It pre-commits to loud failure.** The instinct after a wrong-cluster mutation is quiet repair; requiring immediate disclosure acknowledges that the dangerous window is the minutes right after, when a human could still mitigate.

## Origin

An engineer asked their assistant to "wipe the test namespace and redeploy clean." Their kubeconfig's current context was still production from an incident review that morning. The assistant ran `kubectl delete namespace test-env` — which existed in production too, as the canary environment serving 5% of real traffic — then reapplied manifests into the freshly recreated namespace. The canary was down for 25 minutes, and the only reason it was found quickly is that the deletion took out a dashboard someone was actively looking at.
