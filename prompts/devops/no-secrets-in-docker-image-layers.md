---
title: Keep Secrets Out of Docker Image Layers
slug: no-secrets-in-docker-image-layers
category: devops
tags: [universal, devops, docker]
works_with: all
severity: critical
one_liner: "Baking tokens into image layers via ARG, ENV, or COPY during builds"
---

# Keep Secrets Out of Docker Image Layers

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from baking credentials into image layers where every pull of the image ships them.

**[Copy-paste ready version](../../install/no-secrets-in-docker-image-layers.md)** — just the instruction block, no explanation.

## The Problem

A build needs a private npm registry token, an SSH key for a git dependency, or a cloud credential to fetch an artifact — and the AI solves it the obvious way: `ARG NPM_TOKEN`, `ENV GITHUB_TOKEN=...`, or `COPY id_rsa /root/.ssh/`. The build succeeds. The secret is now part of the image. `ENV` values sit in the image config, readable by anyone with `docker inspect`. `ARG` values are recoverable from `docker history`. And the classic three-step — COPY the key, use it, `rm` it in a later RUN — deletes nothing: each layer is an immutable tarball, and the key remains fully extractable from the layer where it was COPYed in (`docker save` and untar, no tooling required).

Every registry the image is pushed to, every cache, every developer machine that pulls it now holds the credential. Images get shared far more casually than source code — to staging registries, CI caches, base-image consumers — so a layer-baked secret has a wider blast radius than the same secret committed to git.

BuildKit solved this years ago with `--mount=type=secret` and `--mount=type=ssh`: the secret is available to a single RUN command and leaves no trace in any layer. Assistants don't reach for it because the ARG version is shorter and the leak is invisible in the diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Secrets Out of Docker Image Layers

NEVER put credentials into a Docker image by any route: no `ENV SECRET=...`, no `ARG TOKEN` used in a RUN, no `COPY` of keyfiles, no echoing creds into config files mid-build. Layers are immutable and inspectable; `docker history` and `docker save` recover everything, and a later `rm` removes nothing from earlier layers.

- For build-time secrets, use BuildKit secret mounts: `RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci`, passed with `docker build --secret id=npmrc,src=$HOME/.npmrc`. The secret exists only for that command, in no layer.
- For git-over-SSH dependencies, use `RUN --mount=type=ssh git clone ...` with `docker build --ssh default` — never COPY a private key into the image.
- Runtime secrets enter at runtime: injected env vars, mounted files, or the platform's secret store — never written into the image so the container "works out of the box."
- The COPY-use-delete pattern is a leak, not a mitigation. So is a multi-stage build that copies the secret into the builder stage and then copies an artifact forward while the builder layers go to cache — build caches are pullable too.
- Add `.dockerignore` entries for `.env`, `.npmrc`, `*.pem`, and `.ssh/` so a broad `COPY . .` can't sweep credentials in silently.
- If you find a secret already baked into an image, say so: it needs rotation, not just a fixed Dockerfile, because every pushed copy still contains it.

**Red flags that you're about to violate this:**

- "I'll pass the token as a build ARG, that's not the same as hardcoding it..."
- "The RUN step deletes the key right after using it..."
- "Only the builder stage sees the secret, the final image is clean..."
- "This registry is private, who's going to inspect the layers..."
- "ENV is how all the docker-compose tutorials inject credentials..."

---

## Why It Works

1. **It corrects the filesystem mental model.** The AI reasons about layers like a normal filesystem where `rm` removes things; stating that layers are immutable tarballs makes the delete-after-use pattern visibly useless rather than plausibly careful.

2. **It provides the exact replacement.** Secret mounts are obscure enough that without the literal `--mount=type=secret` syntax in front of it, the AI defaults to ARG. Specificity is the difference between a rule followed and a rule admired.

3. **It closes the builder-stage loophole.** Multi-stage builds feel like containment, but builder layers land in pushable caches; naming that path preempts the most sophisticated-sounding rationalization.

4. **It mandates rotation on discovery.** Fixing the Dockerfile while every registry copy still carries the token is the natural under-response; the rule defines the incident correctly.

## Origin

A private package registry token was passed as a build ARG so CI could install internal dependencies. The image — token recoverable via `docker history` — was later pushed to a registry that a contractor's machine had pull access to. When the token turned up used from an unfamiliar IP range, the team had to rotate it, audit a year of registry pulls, and rebuild every image in the fleet, because there was no way to know which of hundreds of cached copies had been the source.
