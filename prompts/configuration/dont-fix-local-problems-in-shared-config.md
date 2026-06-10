---
title: Don't Fix Local Problems in Shared Config
slug: dont-fix-local-problems-in-shared-config
category: configuration
tags: [universal, config, teamwork]
works_with: all
severity: high
one_liner: "Stops edits to team-wide config files to solve one machine's problem"
---

# Don't Fix Local Problems in Shared Config

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing committed, team-wide configuration to work around a problem that only exists on the current machine.

**[Copy-paste ready version](../../install/dont-fix-local-problems-in-shared-config.md)** — just the instruction block, no explanation.

## The Problem

Port 5432 is taken on your machine because you have a second Postgres running. The AI's fix: change the port in `docker-compose.yml` and `config/database.yml` to 5433. Tests pass, the task is done — and the next `git pull` breaks the database connection for every other developer on the team, plus possibly CI, plus possibly a deploy script that nobody remembered reads that file.

AI assistants reach for shared config because it's where the offending value visibly lives. The error says "port 5432 in use," the string `5432` is in a committed file, so the committed file gets edited. The assistant has no concept of "this file is a contract with twelve other machines"; it only sees "this file contains the wrong value for the machine I'm on."

These changes sail through review because they look like deliberate configuration decisions. A reviewer seeing `port: 5433` assumes there was a reason. There was — the reason was one developer's laptop — but the diff doesn't say that, and the cost lands on everyone else, asynchronously, one `git pull` at a time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Fix Local Problems in Shared Config

NEVER modify committed, shared configuration to solve a problem specific to the current machine. Shared config encodes the team's agreement; a local conflict is your problem to absorb locally, not theirs to inherit.

A port collision, a missing local service, or a path that doesn't exist on this machine is a local condition. Fixing it in a committed file exports your environment's quirks to every other environment.

- First ask: would this change be wrong on a teammate's machine or in CI? If yes, it doesn't belong in a committed file.
- Use the project's local-override mechanism instead: `.env.local`, `docker-compose.override.yml`, `config/local.*`, `settings_local.py`, direnv — whatever the project already supports. These exist precisely for this.
- If no override mechanism exists, propose adding one (gitignored) rather than editing the shared file.
- Environment variables that the shared config already reads (`PORT=5433 make dev`) are a fine zero-footprint fix.
- If you genuinely believe the shared default is wrong for everyone, say so explicitly and make that case in the change description — as a deliberate team-wide decision, not a drive-by fix.
- This applies to tool config too: editor settings, linter paths, test runner ports, registry mirrors.

**Red flags that you're about to violate this:**
- "The port was already in use, so I changed it in the compose file."
- "It works now" (on this machine, which is the only one I checked).
- "Everyone probably has the same conflict anyway."
- "It's a tiny config change, easy to revert if anyone complains."
- "I'll mention it in the commit message so people can adjust."

---

## Why It Works

1. **It installs the one question that catches the whole class:** "would this be wrong on another machine?" A shared-config edit for a local problem always fails that test; the AI just never asks it unprompted.
2. **It routes the fix to mechanisms that already exist.** Most stacks have a gitignored override layer; the AI doesn't use it because the error message points at the committed file. Naming the override files redirects the edit.
3. **It separates "the default is wrong for me" from "the default is wrong"** and forces the second claim to be made out loud, where a reviewer can actually evaluate it.

## Origin

A developer's laptop had a corporate proxy that broke the npm registry URL in the committed `.npmrc`, so the assistant helpfully pointed it at a public mirror and committed the change. CI builds started pulling dependencies from an unvetted mirror for three weeks. Nobody noticed until a lockfile diff during an audit showed integrity hashes resolving against a host no one on the team had heard of. The original problem — one laptop's proxy — had been solvable with a user-level `.npmrc` the whole time.
