---
title: Install Dependencies Before COPY Dot in Dockerfiles
slug: dockerfile-deps-before-copy-all
category: devops
tags: [universal, devops, docker]
works_with: all
severity: medium
one_liner: "COPY . . before dependency install, busting the layer cache on every build"
---

# Install Dependencies Before COPY Dot in Dockerfiles

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing Dockerfiles where editing a comment reinstalls every dependency from scratch.

**[Copy-paste ready version](../../install/dockerfile-deps-before-copy-all.md)** — just the instruction block, no explanation.

## The Problem

The two-line Dockerfile body AI assistants love to produce — `COPY . .` followed by `RUN npm install` — is functionally correct and operationally expensive. Docker caches layers by content: a layer is reused only if it and everything above it are unchanged. Put the full source tree into the image before installing dependencies, and every source edit invalidates the COPY layer, which invalidates the install layer below it. Net effect: changing one line of application code reinstalls all dependencies, on every build, forever. A build that should take eight seconds takes six minutes, multiplied across every developer and CI run.

The correct order is boring and well known: copy the manifest and lockfile alone, install, then copy the rest. Dependencies change weekly; source changes hourly; the layer order should match. Assistants get this wrong because `COPY . .` first is the minimal Dockerfile that works, and the cost is invisible at generation time — the first build is slow either way.

The same mistake hides in subtler forms: `COPY . .` before `pip install -r requirements.txt`, an `apt-get install` placed below the source copy, or a cache-perfect Dockerfile "simplified" during refactoring into a cache-hostile one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Install Dependencies Before COPY Dot in Dockerfiles

ALWAYS order Dockerfile layers from least-frequently-changed to most-frequently-changed. Copy dependency manifests alone, install dependencies, and only then `COPY . .` — never the reverse. A `COPY . .` above the install step means every source edit re-runs the full dependency install.

- Node: `COPY package.json package-lock.json ./` then `RUN npm ci` then `COPY . .`
- Python: `COPY requirements.txt ./` (or `pyproject.toml` + lockfile) then `RUN pip install -r requirements.txt` then `COPY . .`
- Go/Rust: copy `go.mod`/`go.sum` or `Cargo.toml`/`Cargo.lock`, fetch/build deps, then copy source.
- System packages (`apt-get install`, `apk add`) change least often of all; they go above the dependency install, never below the source copy.
- Add a `.dockerignore` excluding `.git`, `node_modules`, build output, and local env files — a bloated COPY context both slows the build and invalidates cache with files that don't affect the image.
- When editing an existing Dockerfile, preserve its cache ordering; do not collapse separated COPY steps into one `COPY . .` for tidiness.
- Use the lockfile-honoring install command (`npm ci`, not `npm install`) so the cached layer is also reproducible.

**Red flags that you're about to violate this:**

- "COPY . . first is simpler and the build still passes..."
- "Build speed isn't part of what they asked for..."
- "Merging these COPY lines makes the Dockerfile cleaner..."
- "The deps layer rebuilds either way the first time, so ordering doesn't matter..."
- "It's a small project, the install only takes a minute..."

---

## Why It Works

1. **It teaches the cache model, not just the pattern.** "Least-changed layers on top" generalizes to apt packages, lockfiles, and languages the examples don't cover, where a memorized two-line fix would not.

2. **It defends existing good Dockerfiles.** Half the damage is AIs "simplifying" correct layer ordering during unrelated edits; the explicit preserve-ordering clause covers the refactor path, not just greenfield generation.

3. **It pairs ordering with .dockerignore.** A perfect layer order still thrashes if `.git` churn rides along in the COPY context; fixing one without the other leaves the build mysteriously slow.

4. **It names the per-edit cost.** "Every source edit re-runs the install" converts an abstract inefficiency into a concrete tax the AI can weigh, instead of rounding build time to zero.

## Origin

A team's CI builds crept from 90 seconds to 11 minutes over a year. The Dockerfile had started with proper manifest-first ordering; an assistant doing a "cleanup" pass had consolidated three COPY instructions into one `COPY . .` at the top, and every build since had reinstalled 1,400 npm packages from a cold cache. Nobody connected the slowdown to that commit for months, because the diff looked like pure tidying and the builds still passed.
