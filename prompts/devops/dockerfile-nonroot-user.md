---
title: Run Containers as a Non-Root User
slug: dockerfile-nonroot-user
category: devops
tags: [universal, devops, docker]
works_with: all
severity: high
one_liner: "Containers running as root because the Dockerfile never said otherwise"
---

# Run Containers as a Non-Root User

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping production containers where the app runs as root by silent default.

**[Copy-paste ready version](../../install/dockerfile-nonroot-user.md)** — just the instruction block, no explanation.

## The Problem

A Dockerfile with no `USER` instruction runs everything as root — build steps and, more importantly, the application at runtime. AI-generated Dockerfiles omit `USER` almost universally, because the happy path never requires it: root can bind any port, write any directory, and install anything, so the container "just works" in the demo. The cost is that a single dependency vulnerability or injection bug now hands an attacker root inside the container, which is dramatically more useful for container-escape attempts, raw socket access, and trampling any mounted volume than an unprivileged UID would be.

Worse, when an AI does hit a permission error in a container, its reflex runs in exactly the wrong direction: add `USER root`, `chmod -R 777`, or `--privileged` to make the error disappear, rather than granting the one permission the process needed. Each of these is a one-line "fix" that converts a visible error into an invisible liability.

Official images increasingly provide a ready-made unprivileged user (`node`, `postgres`, `nginx-unprivileged` variants), so the fix usually costs two lines. The AI just never spends them unprompted.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Run Containers as a Non-Root User

ALWAYS end a production Dockerfile with a non-root `USER`. A container with no `USER` instruction runs the application as root, and root in the container is the difference between a contained bug and a foothold.

- Use the image's built-in unprivileged user when one exists (`USER node` on Node images) or create one: `RUN addgroup --system app && adduser --system --ingroup app app` then `USER app`.
- Place `USER` after build steps that need root (package installs) and before the `CMD`/`ENTRYPOINT`. Build as root if needed; never run as root.
- `chown` the specific directories the app writes (`COPY --chown=app:app`, or `chown app:app /app/data`) instead of `chmod -R 777`, which is root-by-other-means.
- Need a port below 1024? Listen on 8080 and map it, rather than keeping root for the bind.
- When a container hits a permission error, fix it by granting the unprivileged user access to the specific path — never by adding `USER root`, deleting the `USER` line, or running the container `--privileged`.
- In Kubernetes manifests you write, set `runAsNonRoot: true` and `allowPrivilegeEscalation: false` in the securityContext so the image-level decision is enforced at admission.

**Red flags that you're about to violate this:**

- "The base image examples don't set USER either..."
- "Permission denied, switching to root is the quickest unblock..."
- "It's containerized anyway, root inside the box is harmless..."
- "chmod 777 on the data dir and everyone's problem is solved..."
- "I'll sort out the user stuff after the container actually runs..."

---

## Why It Works

1. **It frames the omission as a decision.** No `USER` line doesn't read as a choice, so the AI never reconsiders it; stating "absence means root" makes the default visible enough to override.

2. **It blocks the permission-error reflex.** The moment of failure is the moment the AI escalates to root; pre-loading the correct alternative (chown the one path) means there's a specific cheaper move available under pressure.

3. **It dismantles the isolation myth.** "Root in a container is harmless" is folk wisdom the AI has absorbed; pairing root with escape attempts, raw sockets, and mounted volumes replaces the myth with the threat model.

4. **It pushes the rule into the orchestrator.** `runAsNonRoot: true` makes the policy survive future Dockerfile edits — including edits by the next AI that wants to delete the `USER` line.

## Origin

A vulnerability scan flagged a deserialization bug in a sidecar service. The pen-test follow-up showed the exploited process was running as root and had quietly modified files on a volume shared with the main application container — a lateral move that a non-root UID would have failed at the first write. The Dockerfile had been AI-generated eight months earlier; the postmortem's first action item was three characters short of a tweet: `USER app`.
