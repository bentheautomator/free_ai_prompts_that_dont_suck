---
title: Never Prune Docker Without Scoping It
slug: never-prune-docker-without-scoping
category: code-safety
tags: [universal, docker]
works_with: all
severity: critical
one_liner: "AI running docker system prune -a --volumes and deleting other projects' data"
---

# Never Prune Docker Without Scoping It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from solving one project's Docker problem by deleting every project's containers, images, and volumes.

**[Copy-paste ready version](../../install/never-prune-docker-without-scoping.md)** — just the instruction block, no explanation.

## The Problem

Docker misbehaves — disk full, weird caching, a container that won't rebuild — and the AI reaches for `docker system prune -a --volumes`. It's the top search result for every Docker problem, it usually "works," and it is machine-wide: every stopped container, every image not currently in use, every unattached volume, across *all* projects on the host. The volume flag is the killer. Volumes are where Docker keeps data — local Postgres databases, Elasticsearch indexes, weeks of accumulated dev state — and `--volumes` deletes any of them not attached to a running container. The database container you stopped yesterday? Its data volume is "dangling" now. Gone.

The AI's error is a scoping error: it has a one-project problem and applies a whole-machine solution. Docker's own UX encourages this — the prune commands are global by design — but the AI compounds it by not knowing (or checking) what else lives on the machine. Even without `--volumes`, `-a` evicts every cached image: the next `docker compose up` across all your projects re-downloads and rebuilds for an hour.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Prune Docker Without Scoping It

NEVER run machine-wide Docker prune commands to fix a single project's problem. `docker system prune -a --volumes` acts on every project on the host, and the `--volumes` flag deletes data — any volume not attached to a *currently running* container, including the database volumes of containers that merely happen to be stopped.

The core problem: prune commands are global, but your problem is local. A stopped dev database's volume counts as "dangling" and gets destroyed.

- Scope to the project: `docker compose down` (without `-v`!) for this project's containers, `docker rmi <specific image>`, `docker builder prune --filter` for build cache. Fix the thing that's broken, not the daemon's entire state.
- NEVER include `--volumes` in a prune without explicitly listing which volumes will die: `docker volume ls -f dangling=true` first, and identify each one. Volume names like `myapp_pgdata` are databases. Treat them like databases.
- Before any `-a` prune, acknowledge the rebuild cost: every cached image on the machine, re-pulled and rebuilt across all projects. State it and get approval.
- `docker compose down -v` deletes this project's volumes — its local database included. Only with explicit user intent to lose that data.
- Disk-space pressure: diagnose with `docker system df` and present what's using space and what each option deletes, rather than defaulting to the biggest hammer.
- Stopped containers are not garbage. People stop containers to come back to them. Removing them discards their writable layer and their volume attachments.

**Red flags that you're about to violate this:**
- "A full prune will clear out whatever's causing this..."
- "Dangling volumes are by definition unused..."
- "docker compose down -v for a really clean restart..."
- "Disk is full — prune -a is the standard fix..."
- "Everything important is in images, and images rebuild..."

---

## Why It Works

1. **It redefines "dangling."** The AI reads dangling as "garbage"; the rule re-anchors it as "not attached to a running container right now," which includes every stopped database. That single redefinition prevents most of the data loss.

2. **It matches solution scope to problem scope.** Naming the category error — one-project problem, whole-machine command — gives the AI a test it can apply to any cleanup command, not just the ones listed.

3. **It prices the `-a` flag.** "Every project re-pulls and rebuilds" converts a tidy-sounding flag into a visible multi-hour cost that demands user sign-off.

## Origin

An assistant chasing a stale-layer build issue ran `docker system prune -a --volumes` on a developer's laptop. The build issue was fixed. So was the existence of three other projects' local databases, including one holding two weeks of manually crafted test scenarios for a demo scheduled that afternoon. The stale layer could have been handled with `docker build --no-cache` on one image.
