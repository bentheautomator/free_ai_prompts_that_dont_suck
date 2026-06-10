---
title: Keep Volumes Out of Docker Cleanup
slug: no-docker-prune-or-down-volumes
category: devops
tags: [universal, devops, docker]
works_with: all
severity: high
one_liner: "Running compose down -v or prune --volumes and wiping data that lived there"
---

# Keep Volumes Out of Docker Cleanup

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "cleaning up Docker" with flags that quietly include everyone's data volumes.

**[Copy-paste ready version](../../install/no-docker-prune-or-down-volumes.md)** — just the instruction block, no explanation.

## The Problem

Docker cleanup commands come in pairs that differ by one flag and one category of loss. `docker compose down` stops and removes containers; `docker compose down -v` also deletes the named volumes — the Postgres data directory, the uploaded files, the Elasticsearch indices. `docker system prune` clears stopped containers and dangling images; `docker system prune --volumes` adds every volume not currently attached to a *running* container, which on a machine where the stack is stopped means all of them. AI assistants append these flags habitually — `-v` because "clean state" sounds thorough, `--volumes -a -f` because disk-space tasks reward maximal flags, `-f` specifically because it suppresses the confirmation prompt that exists to prevent exactly this.

The damage profile is sneaky. On a developer machine, the local database that held two weeks of carefully constructed test state is gone, and "it's just local" undersells how expensive recreating it is. On anything server-shaped — a staging box, a single-host production deployment running compose, a CI runner with a cached database — the same muscle memory deletes real data. Docker-hosted databases on small production setups are common precisely in the shops least likely to have backups.

A volume is not Docker debris. Containers are designed to be disposable; volumes exist *because* their contents are not.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Volumes Out of Docker Cleanup

NEVER include volumes in Docker cleanup unless the user explicitly asked for data deletion. Containers and images are reproducible from definitions; volumes are where the irreproducible things live — that's why they're volumes.

- Restarting or resetting a stack: `docker compose down` then `up` — without `-v`. Add `-v` only when the user explicitly wants the data gone (e.g. "wipe the database"), and confirm which volumes that includes first: `docker compose config --volumes`.
- Reclaiming disk: start with the safe tiers — `docker image prune`, `docker builder prune`, `docker container prune` — and report the space freed. `docker system prune --volumes` is not a disk-space command; it's a data-deletion command with disk-space side effects.
- Before any volume removal, list what exists and what's attached: `docker volume ls` and `docker ps -a --filter volume=<name>`. A volume "not in use" by a *stopped* database container is not unused; it's the database.
- Never add `-f`/`--force` to prune commands to skip the confirmation prompt — the prompt is the safety mechanism, and in a non-interactive session the right move is to show the user the command and let them run it.
- Treat bind mounts with the same respect in reverse: `rm -rf` of a host directory that compose mounts is volume deletion by another door.
- If a volume genuinely should be deleted, name it specifically (`docker volume rm <name>`) rather than reaching for bulk flags that delete categories.

**Red flags that you're about to violate this:**

- "down -v gives us a properly clean restart..."
- "The volumes aren't attached to any running container, so they're orphaned..."
- "It's a dev machine, the data is throwaway by definition..."
- "I'll add -f so the script runs non-interactively..."
- "system prune --volumes -a frees the most space in one command..."

---

## Why It Works

1. **It states the design intent of volumes.** "Volumes exist because their contents aren't reproducible" reframes them from Docker clutter to the one category cleanup must exclude — the inverse of how the AI's bulk-flag instinct sorts them.

2. **It redefines "in use."** The `--volumes` prune logic counts only *running* containers, and the AI inherits that definition; pointing out that a stopped database's volume is the database closes the loophole the flag itself creates.

3. **It tiers the disk-space task.** Most volume wipes start as legitimate space-reclaiming; providing the safe-tier sequence with a report-back step satisfies the original request before the dangerous flag gets considered.

4. **It defends the confirmation prompt.** `-f` exists to be added reflexively in scripts; declaring the prompt itself the safety mechanism makes suppressing it a visible decision instead of a syntax habit.

## Origin

Asked to "free up some disk space" on a shared staging server, an assistant ran `docker system prune -a --volumes -f` — maximal flags, no prompt. The stack happened to be stopped for a deploy, so every volume qualified as unattached: the staging database, three weeks of QA test data, and the local object store used for upload testing all evaporated in four seconds. Disk usage improved dramatically. So did the team's backup policy, eventually, after two days of rebuilding staging from fragments.
