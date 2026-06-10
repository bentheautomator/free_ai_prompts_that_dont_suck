---
title: Verify Tools Exist Before Prescribing Them
slug: verify-tools-exist-before-prescribing-them
category: context
tags: [universal, environment, assumptions]
works_with: all
severity: medium
one_liner: "AI building instructions around docker, jq, and make the user doesn't have"
---

# Verify Tools Exist Before Prescribing Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from assuming the user's machine has every CLI tool a well-equipped machine might have.

**[Copy-paste ready version](../../install/verify-tools-exist-before-prescribing-them.md)** — just the instruction block, no explanation.

## The Problem

The AI's imagined development machine has everything: docker, jq, make, gh, curl, python3, redis-cli, watch, tree. So solutions get built on that machine — a five-step procedure whose third step is `jq`-parsing some JSON, delivered to a user who doesn't have jq, on a locked-down corporate laptop where installing it requires a ticket. The procedure dies at step three, the user reports back, and the AI rebuilds the solution around the next tool it shouldn't have assumed.

The compounding version is worse than the single miss. Multi-step instructions with two or three assumed tools fail serially: install docker (can't — no admin rights), okay use podman (not installed either), okay... Each round-trip costs minutes and erodes the user's confidence that any step was grounded in their reality. Agentic assistants have a sharper version of the problem: a script written around an assumed tool fails halfway through execution, leaving whatever state the first half created.

When the AI can run commands, `command -v docker` answers the question in milliseconds. When it can't, the solution can either check-then-act, prefer tools the task's own context guarantees, or ask.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Tools Exist Before Prescribing Them

NEVER build a solution around a CLI tool you haven't confirmed exists in the user's environment. Your mental image of a development machine — docker, jq, make, gh, everything installed — is a composite, not this user's laptop.

Instructions with assumed tools fail serially, one round-trip per wrong assumption, and scripts built on them fail halfway, leaving partial state behind.

**Before prescribing or scripting around any tool:**
- If you can execute commands, check first: `command -v <tool>` (or `which`, or `Get-Command` on PowerShell) — milliseconds, definitive
- Prefer tools the context already guarantees: if the project has a `package.json`, node exists; a `Dockerfile` in active use implies docker; the language runtime of the repo is a safe bet — random conveniences like `jq`, `watch`, `tree`, `httpie` are not
- For multi-step instructions you can't verify, front-load the requirements ("this needs docker and jq") instead of burying tool dependencies in step three where failure costs the most
- Have a degraded path for the common misses: parsing JSON with python/node instead of jq, `curl` vs `wget`, raw git commands instead of `gh`
- In scripts, check for required tools at the top and fail fast with a clear message — never let a missing binary kill a script halfway through its side effects
- Don't assume installation is possible: corporate machines, containers, and CI runners often can't just `brew install` the gap

**Red flags that you're about to violate this:**
- "Just pipe it through jq..."
- "Everyone has make installed..."
- "Spin it up with docker compose — they'll have docker..."
- "gh pr create will handle the rest..."
- "If it's missing they can quickly install it..."
- Writing step three around a tool you never checked while step one was available for checking it

---

## Why It Works

1. **It names the composite-machine illusion.** The AI's imagined environment is a union of every machine in its training data; calling it a composite explains why "everyone has X" feels true and isn't.

2. **It grades tools by evidence.** "The repo's own stack is a safe bet; conveniences are not" gives a usable heuristic for the can't-verify case, instead of an unactionable "verify everything."

3. **It moves failure to the cheapest point.** Front-loaded requirements and fail-fast tool checks relocate the inevitable miss from step-three-mid-script (expensive, stateful) to step zero (free).

4. **It pre-builds the fallbacks.** Listing degraded paths (python for jq, curl for httpie) means a missing tool costs a substitution, not a redesign.

## Origin

A user asked for help bulk-updating labels via their git host's API. The AI delivered a slick one-liner: `gh` piped through `jq` inside a `bash` loop. The user was on a corporate Windows machine: no gh, no jq, Git Bash of uncertain vintage, and a software-install policy measured in weeks. Four rebuild round-trips later the working solution turned out to be a twelve-line script in the language the user's own repo was written in — using a runtime that had been verifiably present the entire time.
