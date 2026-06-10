---
title: Pin Dockerfile Base Image Tags
slug: dockerfile-pin-base-image-tags
category: devops
tags: [universal, devops, docker]
works_with: all
severity: high
one_liner: "Writing FROM node:latest so every build pulls a different base image"
---

# Pin Dockerfile Base Image Tags

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from basing your images on whatever `latest` happens to mean this week.

**[Copy-paste ready version](../../install/dockerfile-pin-base-image-tags.md)** — just the instruction block, no explanation.

## The Problem

Generate a Dockerfile with almost any AI assistant and the odds are good the first line is `FROM node:latest` or `FROM python:3`. Both are moving targets. `latest` re-points at every major release; `python:3` re-pointed from 3.11 to 3.12 to 3.13 without asking anyone. The image that built fine on Tuesday fails on Thursday because the base OS swapped Debian versions, dropped a system library, or shipped a new language runtime your dependencies haven't met yet. And because the tag in the Dockerfile didn't change, the diff for "what broke the build" is empty.

The deeper damage is reproducibility. A rollback re-builds the "old" image from the same Dockerfile and gets a different base than the original build did, so rolling back doesn't actually restore the previous behavior. Two developers building the same commit get different images. The artifact you tested is not provably the artifact you ship.

Assistants write `latest` because it appears in thousands of tutorials and it always works at generation time. The cost lands weeks later, on someone else, which is the exact profile of a default worth overriding.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Pin Dockerfile Base Image Tags

NEVER write `FROM image:latest`, a bare `FROM image`, or a major-only tag like `python:3` in a Dockerfile. Unpinned base images make builds non-reproducible: the same Dockerfile produces different images on different days, and rollbacks rebuild on a base the original was never tested with.

- Pin to at least minor version plus variant: `FROM node:20.12-bookworm-slim`, `FROM python:3.12.3-slim`, not `node:latest` or `python:3`.
- For production images, prefer pinning by digest for full immutability: `FROM node:20.12-bookworm-slim@sha256:...` (get the digest with `docker buildx imagetools inspect <image:tag>`).
- Pin every stage of a multi-stage build, including the throwaway builder stage and any `COPY --from=<image>` references.
- The same applies to images referenced outside Dockerfiles that you're asked to write: compose files, CI service containers, base images in build scripts.
- When updating a pinned base, change the pin explicitly in its own commit so the upgrade is visible, testable, and revertible, instead of arriving as a silent side effect of the next build.
- If the project has no convention yet, choose the current stable version and pin it; do not leave the choice to the registry.

**Red flags that you're about to violate this:**

- "latest keeps them automatically up to date with security patches..."
- "Every tutorial Dockerfile uses node:latest..."
- "Pinning means someone has to maintain version bumps..."
- "It's just the builder stage, the final image is what matters..."
- "python:3 is pinned enough, the major version won't change behavior..."

---

## Why It Works

1. **It attacks the "auto-updates are a feature" framing.** Unpinned tags do deliver updates — at a random time, with no diff, no review, and no test run attached. Naming that trade makes "latest = patched" stop sounding like a benefit.

2. **It defines the minimum pin precisely.** "Pin your images" alone gets satisfied with `python:3`; specifying minor-plus-variant (and digest for prod) removes the wiggle room.

3. **It covers the places pins get forgotten.** Builder stages, `COPY --from`, and compose files are where one unpinned image survives the cleanup and keeps the nondeterminism alive.

4. **It makes upgrades a visible event.** Routing base bumps through explicit commits converts "the build broke mysteriously" into "the upgrade PR failed CI," which is the entire point of pinning.

## Origin

A service's image was built `FROM node:latest` for a year without incident. Then a major Node release changed OpenSSL defaults, the registry re-pointed `latest`, and the next routine deploy shipped an image whose TLS connections to a legacy internal API failed at runtime. The emergency rollback rebuilt from the identical Dockerfile, pulled the identical new base, and failed identically — the team had to bisect base image digests at midnight to find a version that matched what production had actually been running.
