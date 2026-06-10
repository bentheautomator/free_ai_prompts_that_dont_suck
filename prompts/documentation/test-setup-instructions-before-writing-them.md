---
title: Test Setup Instructions Before Writing Them
slug: test-setup-instructions-before-writing-them
category: documentation
tags: [universal, docs]
works_with: all
severity: high
one_liner: "Setup guides written from imagination that fail on the first command"
---

# Test Setup Instructions Before Writing Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing installation and setup instructions that nobody, including the AI, has ever successfully followed.

**[Copy-paste ready version](../../install/test-setup-instructions-before-writing-them.md)** — just the instruction block, no explanation.

## The Problem

"Add a Getting Started section to the README" produces a tidy sequence: clone, `npm install`, `cp .env.example .env`, `npm run dev`. It looks like every Getting Started section ever written, which is exactly the problem — it was generated from the genre, not the repo. This repo has no `.env.example`. The dev script is `npm run start:dev`. `npm install` fails without the private registry token that nothing mentions. Each step is plausible; the sequence has never been executed by anyone.

Setup instructions are uniquely punishing when wrong because their entire audience is people who can't yet help themselves: new hires, first-time contributors, evaluators with ten minutes of patience. They follow the steps literally, hit the failure, and have no model of the project to debug with. A senior engineer loses five minutes; a newcomer loses the afternoon or just leaves.

AI assistants write untested setup docs because writing is cheap and executing is work. The model can emit the canonical install sequence for any stack from memory, and memory is where these instructions come from, not the repo in front of it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Test Setup Instructions Before Writing Them

NEVER publish setup or installation instructions you haven't executed or verified against the repo, step by step. Setup docs are read exclusively by people who cannot debug your mistakes.

The problem: setup instructions generated from what projects "usually" need fail on contact with this project's actual scripts, files, and prerequisites.

Rules:
- If you can execute commands, run the full sequence from a clean state (fresh clone or clean directory) and write down what actually worked, including the errors you hit and resolved
- If you cannot execute, verify each step against the repo: the script exists in `package.json`/`Makefile`, the referenced file (`.env.example`, `docker-compose.yml`) exists at that path, the command matches the tool versions in lockfiles
- State prerequisites explicitly with versions where the repo pins them (engines field, `.tool-versions`, Dockerfile base image). "Requires Node" is not a prerequisite; "Requires Node 20+ (see `.nvmrc`)" is
- Include the expected outcome of the final step ("server starts on http://localhost:3000") so readers can tell success from silent failure
- Never include a step you couldn't verify without marking it: "Untested: may require X on Apple Silicon"
- A shorter verified sequence beats a complete imagined one. Omit what you can't confirm rather than guessing it

**Red flags that you're about to violate this:**
- "Every project of this type installs the same way..."
- "The standard commands will probably work..."
- "I'll write the docs first and someone can verify later..."
- "There's surely a .env.example, there always is..."
- "Running it from scratch would take too long..."
- "The README pattern from similar repos applies here..."

---

## Why It Works

1. **Execution is the only oracle for setup docs.** No review process catches a missing registry token or a renamed script; only running the steps from a clean state does. The rule mandates the one check that works.

2. **The fallback keeps the rule executable without a shell.** Verifying that each referenced script, file, and path exists in the repo catches the majority of genre-generated failures even when nothing can be run.

3. **Expected-outcome lines give readers a success signal.** Most setup failures are silent (server starts on the wrong port, env vars unread). Telling readers what success looks like converts confusion into a specific bug report.

4. **It prices the audience correctly.** Naming that setup readers can't self-rescue flips the model's cost model: the omission that costs the author one verification costs each reader a session.

## Origin

A team published a contributor guide whose setup section was AI-written and reviewed by three people who already had working environments, so none of them ran it. The first external contributor followed it exactly and hit failures at steps two, four, and five: a renamed script, a Docker network the compose file no longer defined, and a seed command that required a flag the guide omitted. They filed one polite issue and never came back. The guide was fixed by finally doing what should have happened first: a fresh clone and a stopwatch.
