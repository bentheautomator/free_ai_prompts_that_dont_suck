---
title: Deploy by Immutable Image Tag, Never Latest
slug: deploy-immutable-image-tags
category: devops
tags: [universal, devops, deploys]
works_with: all
severity: high
one_liner: "Deploying image:latest so nobody can say what is running or roll it back"
---

# Deploy by Immutable Image Tag, Never Latest

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wiring deployments to mutable tags, making "what's running in prod" unanswerable and rollback meaningless.

**[Copy-paste ready version](../../install/deploy-immutable-image-tags.md)** — just the instruction block, no explanation.

## The Problem

This is the deploy-side twin of the unpinned base image, and it's worse. An AI writing a Kubernetes Deployment, an ECS task definition, or a compose file will happily set `image: myapp:latest` — and now the manifest no longer identifies a version. Whatever happens to be tagged `latest` at pull time runs. Two pods scheduled an hour apart can run different code. "Roll back" becomes a trick question: redeploying the same manifest pulls the same mutable tag, which now points at the bad build. And because the manifest never changes between releases, your GitOps history, `kubectl rollout undo`, and diff-based review all see nothing happening at all.

The companion failure is "deploying" by re-pushing `latest` and bouncing pods — sometimes with `imagePullPolicy: Always` doing load-bearing work, sometimes with the AI restarting pods and hoping the node pulls fresh. Either way, the release process has no artifact identity: you cannot name what you shipped, prove what a node is running, or pin an incident to a version.

Assistants do this because `latest` is what half the internet's example manifests use, and because tagging-per-release requires a convention they weren't told about.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Deploy by Immutable Image Tag, Never Latest

NEVER reference `:latest`, an untagged image, or any mutable tag (`stable`, `prod`, `main`) in a deployment manifest, task definition, compose file, or Helm values. A deploy must name an immutable artifact; otherwise rollback, audit, and "what is running right now" are all undefined.

- Tag images per build with something unique and traceable: the git SHA (`myapp:3f2a91c`), or version plus SHA (`myapp:1.4.2-3f2a91c`). For the strongest guarantee, deploy by digest: `myapp@sha256:...`.
- A release is a manifest change: bump the tag in the Deployment/values file, apply, done. Rollback is re-applying the previous tag — which only works if the previous tag still points at the previous build, i.e., never if the tag is `latest`.
- Never "deploy" by re-pushing an existing tag and restarting pods. Mutable-tag re-push means two replicas can run different code under the same name and the registry has silently lost the old build's address.
- Do not set `imagePullPolicy: Always` to make mutable tags behave; that's a workaround that adds a registry dependency to every pod start and still can't tell you what's running.
- If the project currently deploys `latest`, flag it before making changes that assume version identity (rollbacks, canaries, incident timelines) — those features don't actually exist yet.

**Red flags that you're about to violate this:**

- "latest is what the existing manifests use, I'll stay consistent..."
- "Re-pushing the tag and restarting the pods is the fastest way to ship this fix..."
- "imagePullPolicy: Always means the pods will always get the newest build, problem solved..."
- "Tagging every build clutters the registry..."
- "We can always tell what's running from the deploy timestamps..."

---

## Why It Works

1. **It redefines a deploy as a manifest diff.** Once "release = change the tag in git" is the model, `latest` is self-evidently broken — the manifest can't diff. This reframe does more work than any list of prohibitions.

2. **It names what mutable tags silently delete.** Rollback targets, audit answers, and incident timelines are features teams assume they have; pointing out that `latest` removed them turns an aesthetic preference into a capability question.

3. **It blocks the two workaround patterns by name.** Re-push-and-restart and `imagePullPolicy: Always` are exactly how AIs keep `latest` limping along; prohibiting them specifically prevents the rule being satisfied in letter only.

4. **It includes a brownfield clause.** Most repos already deploy `latest`; requiring the AI to flag it stops it from building canary or rollback logic on top of a versioning scheme that isn't there.

## Origin

During an incident, a team tried to roll back by redeploying the previous Kubernetes manifest — which was byte-identical to the current one, because both said `image: api:latest`. The bad build was the only thing the tag pointed at; the previous build existed in the registry only as an untagged digest that took forty minutes of `docker inspect` archaeology to locate. The outage lasted exactly that much longer than it needed to, and the first post-incident commit replaced `latest` with SHA tags everywhere.
