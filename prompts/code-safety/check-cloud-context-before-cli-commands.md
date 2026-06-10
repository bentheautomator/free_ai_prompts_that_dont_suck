---
title: Check Cloud Context Before CLI Commands
slug: check-cloud-context-before-cli-commands
category: code-safety
tags: [universal, production, cloud]
works_with: all
severity: critical
one_liner: "AI trusting whatever account, region, or cluster the CLI was last pointed at"
---

# Check Cloud Context Before CLI Commands

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running cloud and cluster commands against whichever account or context happened to be active.

**[Copy-paste ready version](../../install/check-cloud-context-before-cli-commands.md)** — just the instruction block, no explanation.

## The Problem

Cloud CLIs are stateful in a way that almost nothing else on a dev machine is. `kubectl` acts on the *current context* — whatever cluster someone was poking at last week. `aws` uses whatever `AWS_PROFILE` is exported or whatever `[default]` resolves to. `gcloud` has an active project; `az` has an active subscription. The command says nothing about the target; the target is ambient state, set by the last human who touched the machine, persisting silently across sessions.

So the AI runs `kubectl delete deployment api` to clean up its test deployment, and the current context is the production cluster, because the on-call engineer used this terminal during last week's incident. Or it creates test resources that land in the company's billing-sensitive production account instead of the sandbox. The commands are *correct* — right resource names, right syntax — and aimed by a setting nobody has looked at in days. Mutating commands fired into unverified ambient context is the cloud version of shooting without checking where the gun is pointed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Cloud Context Before CLI Commands

ALWAYS verify which account, project, region, cluster, or subscription a cloud CLI will act on before running any mutating command. Cloud CLIs aim at ambient state — the current context is whatever the last human left it pointing at, and it is frequently production.

The core problem: the command names the resource but not the target environment. `kubectl delete deployment api` is identical whether the context is your test cluster or prod; only the ambient setting differs, and it persists invisibly across sessions.

- Check first, every session, before anything that mutates: `kubectl config current-context`, `aws sts get-caller-identity` (plus `echo $AWS_PROFILE` and region), `gcloud config list`, `az account show`. State the result: "Context is `staging-eu`, account 1234, proceeding."
- If the context contains prod-flavored strings (prod, live, prd, main) or you can't tell what it is, stop and confirm with the user before any mutation.
- Prefer explicit targeting over ambient state in the commands themselves: `kubectl --context=dev-cluster -n myteam ...`, `aws --profile sandbox --region us-east-1 ...`. A command that names its target is auditable; one that inherits it is a guess.
- Never *switch* shared context as a side effect (`kubectl config use-context`, `gcloud config set project`) without telling the user — you're re-aiming every future command they run in that terminal, which is this same failure planted for later.
- Namespaces count: the right cluster with the wrong namespace still deletes someone else's deployment. Verify both halves.
- Creating resources needs this too — test resources created in the wrong account are a billing and security mess even though nothing was deleted.

**Red flags that you're about to violate this:**
- "kubectl is already configured, I'll go ahead..."
- "The default profile is presumably the dev account..."
- "I set the context earlier, it's fine..." (earlier was 400 commands ago)
- "It's a delete of *my* test deployment, the cluster barely matters..."
- "Checking the account every time is paranoid..."

---

## Why It Works

1. **It makes ambient state a stated fact.** Requiring the AI to print and announce the context converts an invisible setting into a line of output that either matches the task or visibly doesn't — and prod-flavored strings in that line are unmissable.

2. **It promotes explicit targeting.** `--context`/`--profile` flags move the target from machine state into the command text, where it can be reviewed before execution and audited after. Ambient aiming disappears as a failure class.

3. **It blocks context-switching as a side effect.** The rule covers not just firing into the wrong context but quietly re-aiming the terminal — protecting the *next* command, including the human's.

## Origin

An assistant finished testing a deployment and cleaned up with `kubectl delete deployment,service,ingress -l app=demo`. The terminal's kubectl context was still pointed at the production cluster from an incident review two days prior, and a production app shared the `app=demo` label from its own demo-mode rollout. Eleven seconds of `current-context` checking would have cost less than the forty minutes of downtime did.
