---
title: Claim Files Before Parallel Edits
slug: claim-files-before-parallel-edits
category: agents-and-automation
tags: [universal, agents, multi-agent]
works_with: all
severity: high
one_liner: "Two agents editing one file and silently erasing each other's work"
---

# Claim Files Before Parallel Edits

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents parallel agents from writing to the same files and silently overwriting each other's changes.

**[Copy-paste ready version](../../install/claim-files-before-parallel-edits.md)** — just the instruction block, no explanation.

## The Problem

Two agents work the same repository in parallel — a deliberate fan-out, or just a user running two sessions. Agent A reads `routes.ts`, plans an edit. Agent B, between A's read and A's write, adds its own handler to the same file. Agent A then writes its version — constructed from the pre-B content — and B's handler is gone. No error, no conflict marker, no trace. B's work simply stops existing, and B doesn't know, and A doesn't know, and the user finds out when the feature B built isn't there.

Filesystems don't merge. Git gives concurrent editors conflict detection; the working tree gives them last-writer-wins. Agents are built around a single-writer assumption — read, decide, write, with no concept that the world changed in between — so when multiple sessions share a tree, every read-modify-write cycle is a race. The longer an agent holds a file "in its head" before writing, the wider the window.

The shared hotspots make it worse. Even with cleanly divided tasks, both agents will touch the same registration files: the route index, the barrel export, the changelog, package.json, the migrations directory. Task partitioning by feature does not partition these files; they're where parallel work collides by design.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Claim Files Before Parallel Edits

NEVER edit a file another active agent might also be editing without coordinating first. The working tree has no merge — concurrent edits resolve as last-writer-wins, and the loser's work vanishes without an error.

The core problem: your read-modify-write cycle assumes the file can't change between your read and your write. With parallel sessions, it can, and writing from a stale read silently erases the other writer's changes.

- If you know you're part of a parallel run, work from an explicit file partition: each agent owns a disjoint set of files or directories, stated up front. Don't touch files outside your claim; if you must, that's a coordination event, not a quick edit.
- Treat shared hotspot files as the danger zone regardless of partitioning: barrel exports and index files, route or plugin registries, changelogs, lockfiles and manifests. For these: claim them in the coordination notes, batch your changes, and re-read the file immediately before writing.
- Use append-friendly and conflict-avoidant patterns where possible: one new file per agent instead of edits to one shared file; per-agent scratch directories; generated registries built from the filesystem rather than hand-maintained lists.
- Keep the read-to-write window short for any potentially shared file: re-read, apply your edit to the fresh content, write promptly. Never write a shared file from content you read several steps ago.
- If you find content in a file that you didn't put there and don't recognize, STOP — that's another writer's live work. Preserve it; integrate around it; never "clean it up."
- When the workspace can't be partitioned, serialize instead: agents take turns or work in separate worktrees and merge through git, which at least detects the conflicts the filesystem won't.

**Red flags that you're about to violate this:**
- "I read this file earlier, I'll write my updated version now..."
- "This index file just needs one quick line from me..."
- "There's some unfamiliar code here — probably stale, I'll remove it..."
- "We divided the tasks, so we can't be touching the same files..."
- "I'll fix up the changelog at the end like always..."

---

## Why It Works

1. **It names the missing primitive.** Agents implicitly assume something merges their writes. Stating flatly that the working tree is last-writer-wins replaces a false safety assumption with the real failure model.

2. **It targets hotspots, not just partitions.** The intuitive defense — "we split the tasks" — fails precisely at registries, barrels, and changelogs. Calling these out by name covers the collisions that task partitioning structurally can't.

3. **It shrinks the race window mechanically.** "Re-read immediately before writing shared files" doesn't eliminate the race but cuts its width from minutes to milliseconds, which in practice is the difference between weekly and never.

4. **It protects the other agent's work at discovery time.** The second-order failure — finding a sibling's fresh code and deleting it as cruft — gets its own hard stop, because that's where a race becomes a double loss.

## Origin

A fan-out of three agents, each adding an API endpoint, was partitioned cleanly by feature directory — but all three needed one line in the shared route index. Agent two wrote the index from a read taken before agents one and three had added their lines; the final state registered one endpoint of three. Both missing endpoints' handler files existed, fully implemented and tested, silently unreachable. The team spent half a day treating it as a routing bug before someone compared file mtimes and reconstructed the race.
