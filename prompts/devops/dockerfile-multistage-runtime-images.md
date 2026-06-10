---
title: Ship Runtime Images, Not Build Environments
slug: dockerfile-multistage-runtime-images
category: devops
tags: [universal, devops, docker]
works_with: all
severity: medium
one_liner: "Shipping compilers, dev dependencies, and source in the production image"
---

# Ship Runtime Images, Not Build Environments

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from shipping a 2 GB image that contains the compiler, the test suite, and everything else production will never execute.

**[Copy-paste ready version](../../install/dockerfile-multistage-runtime-images.md)** — just the instruction block, no explanation.

## The Problem

The single-stage Dockerfile an AI writes for a TypeScript service installs all of `devDependencies`, compiles, and ships the result — along with the TypeScript compiler, the test framework, the source files, the build cache, and a full `node_modules` of tooling. A Go service gets shipped inside the entire `golang` build image instead of the 10 MB binary it produced. The image works, so nothing complains. Meanwhile every deploy pulls hundreds of megabytes it will never execute, node startup and autoscaling slow down by the size of the pull, registry storage bills grow, and the vulnerability scanner files tickets for CVEs in build tools that exist in production for no reason.

Multi-stage builds are the standard fix and have been for years: build in one stage, `COPY --from=build` only the artifacts into a slim runtime stage. AI assistants know the pattern perfectly well when asked — they just don't apply it by default, because a single-stage Dockerfile is shorter and "make the image small" was never an explicit requirement.

The bloat also has a security texture: every binary in the image is attack surface, and a shell plus compiler toolchain in a compromised container is a gift.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Ship Runtime Images, Not Build Environments

ALWAYS use a multi-stage build for compiled or bundled applications. The production image contains the runtime and the built artifact — not compilers, dev dependencies, source files, test suites, or package manager caches.

- Pattern: a `build` stage (`FROM node:20.12-slim AS build`) that installs everything and compiles, then a runtime stage (`FROM node:20.12-slim`) that does `COPY --from=build /app/dist ./dist` plus a production-only dependency install (`npm ci --omit=dev`).
- Compiled languages go further: build in the full toolchain image, run from `debian:slim`, `distroless`, or `alpine` with just the binary. A Go or Rust service has no business shipping its compiler.
- Do not ship: `devDependencies`, `.git`, test directories, build caches, docs, or source files the runtime doesn't read. If the entrypoint doesn't execute it, it doesn't belong in the final stage.
- Keep `apt-get install` in the build stage unless the runtime genuinely needs the library; when it does, install the runtime lib (`libpq5`), not the dev package (`libpq-dev`).
- Maintain a `.dockerignore` so the build context itself stays lean.
- When you finish a Dockerfile, report the final image size (`docker images <name>`). If a Node service image is over ~400 MB or a Go service over ~50 MB, something that doesn't belong is in there.

**Red flags that you're about to violate this:**

- "Single-stage is simpler and image size wasn't in the requirements..."
- "Disk is cheap, a fat image hurts nobody..."
- "Keeping devDependencies in the image makes debugging in prod easier..."
- "I'll copy the whole /app directory forward, sorting out what's needed is fiddly..."
- "The scanner findings are all in build tools, so they're not real vulnerabilities..."

---

## Why It Works

1. **It states the membership test.** "If the entrypoint doesn't execute it, it doesn't belong" converts a vague aspiration (small images) into a per-file decision the AI can apply while writing each COPY.

2. **It prices the bloat in operational terms.** Pull time on scale-up, registry cost, and CVE noise are consequences the AI can weigh; "disk is cheap" only survives while the costs stay unnamed.

3. **It adds a verifiable exit check.** Reporting the final size with rough thresholds turns "looks done" into a measurement, and a 1.8 GB Node image fails loudly.

4. **It heads off the debugging rationalization.** "Dev deps help debug prod" is the most respectable-sounding excuse for bloat; naming it as a red flag forces the AI to justify it explicitly rather than assume it.

## Origin

An autoscaling group was missing its scale-up SLO during traffic spikes; new nodes took over four minutes to serve traffic. Most of that was image pull: the service image had grown to 2.3 GB, single-stage, carrying a full build toolchain, three years of dev dependencies, and the repo's `.git` directory. A two-hour multi-stage refactor cut it to 180 MB, and scale-up time dropped under a minute — the capacity problem had been a Dockerfile problem all along.
