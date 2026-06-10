---
title: Verify the Target Environment Before Running Anything
slug: verify-target-environment-before-running
category: code-safety
tags: [universal, production]
works_with: all
severity: critical
one_liner: "AI running commands against production when the user meant staging or local"
---

# Verify the Target Environment Before Running Anything

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from pointing a command at production because that's where the ambient config happened to point.

**[Copy-paste ready version](../../install/verify-target-environment-before-running.md)** — just the instruction block, no explanation.

## The Problem

"Run the cleanup script" means staging to the user, because in their head they've been working on staging all afternoon. The AI runs the script, the script reads `.env`, and `.env` contains the production API URL from the last time someone debugged a prod issue. The cleanup runs against production. Nobody typed the word "production" at any point.

This is the defining property of environment accidents: the target is implicit. It hides in `.env` files, in `API_BASE_URL` exports from an earlier shell session, in config files with a `default:` block, in whichever context was active last. AI assistants execute against whatever the ambient configuration resolves to, and they never ask "resolves to *what*?" because the command itself looks identical either way. `python cleanup.py` is six characters of pure ambiguity.

The fix is not caution in general. It's one specific habit: make the target explicit before any command that mutates state, every time.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify the Target Environment Before Running Anything

Before running any command or script that mutates state, ALWAYS determine and state which environment it will hit. Never let the target be whatever the ambient config happens to resolve to.

The core problem: the target environment is usually implicit — buried in `.env` files, exported variables, or config defaults — and a command pointed at production looks identical to one pointed at local.

- Resolve the actual target first: read the `.env`/config the script loads, print the relevant variables (`echo $API_BASE_URL`, `printenv | grep -i url`), check which config block is active.
- State it out loud before executing: "This will run against `api.staging.example.com`." If you can't complete that sentence with a concrete hostname or environment name, you're not ready to run it.
- If anything resolves to a production-looking target (prod, live, www, a real customer domain) and the user didn't explicitly say production, STOP and confirm.
- Treat ambiguous instructions ("the database", "the API", "the server") as unresolved until the user or the config makes the environment explicit.
- Prefer passing the target explicitly (`--env staging`, explicit URLs) over relying on defaults, and say which one you passed.
- Be suspicious of leftover state: an exported variable or `.env` edit from earlier debugging silently retargets everything that follows.

**Red flags that you're about to violate this:**
- "The script handles its own config, I'll just run it..."
- "We've been working on staging, so this obviously targets staging..."
- "The .env is whatever it was before, that's not my concern..."
- "It's a read-mostly script, the target barely matters..."
- "I'll run it and we'll see where it connects..."

---

## Why It Works

1. **It makes the implicit target a required output.** The AI cannot state "this hits api.staging.example.com" without actually resolving the config — the sentence forces the verification.

2. **It defines a hard stop condition.** "Production-looking target + user didn't say production = stop" is mechanical. No judgment call survives contact with the word "prod" in a hostname.

3. **It names ambient state as the adversary.** Leftover exports and edited `.env` files are how most of these accidents happen; flagging them turns "the config is whatever it is" into a thing to check rather than assume.

## Origin

An assistant was asked to "clear out the test users" with a maintenance script. The script read its connection target from `.env`, which a developer had pointed at production two days earlier to investigate a support ticket and never reverted. The script deleted every account matching the test-user pattern — including a batch of real users whose emails happened to match. One `echo` of the URL beforehand would have ended the session differently.
