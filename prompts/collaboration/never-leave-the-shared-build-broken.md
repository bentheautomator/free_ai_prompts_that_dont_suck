---
title: Never Leave the Shared Build Broken
slug: never-leave-the-shared-build-broken
category: collaboration
tags: [universal, teamwork, ci]
works_with: all
severity: high
one_liner: "Stops breaking the build everyone depends on and moving on to the next task"
---

# Never Leave the Shared Build Broken

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from breaking the build or dev environment that the whole team depends on and treating it as someone else's problem.

**[Copy-paste ready version](../../install/never-leave-the-shared-build-broken.md)** — just the instruction block, no explanation.

## The Problem

The AI finishes its task: the feature works, its tests pass, done. What it didn't check is that its change broke the main build — a type error in a module it touched but didn't run, a missing file in the Docker build, a renamed script that CI still calls, a `docker-compose.yml` tweak that no longer boots on anyone else's machine. The AI reports success and the conversation moves on. Twenty minutes later, every developer who pulls main is broken, and none of them know why.

A broken shared build is the most expensive kind of breakage because it multiplies: it doesn't cost one person an hour, it costs every person on the team an hour, plus the time to figure out whose change did it. It blocks unrelated work, stalls deploys, and trains people to stop trusting green checkmarks. And the person best positioned to fix it — the one who made the change, with full context — has already moved on.

AI assistants do this by default because "the task" is scoped to the feature, not to the ecosystem the feature lives in. The build, the dev container, the seed scripts, the CI config: these are everyone's, and a definition of done that ignores them optimizes for the AI's task at the team's expense.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Leave the Shared Build Broken

NEVER finish a task leaving the shared build, test suite, or dev environment broken. "My feature works" is not done; "the team's world still works" is done.

Everyone on the team pays for a broken build, and the cheapest moment to fix it is right now, while you have the context.

- Before declaring a task complete, run the project's standard verification — the full build, the lint command, the test suite the team actually uses — not just the tests for your change.
- If you changed anything in the dev environment (Dockerfile, docker-compose, devcontainer, Makefile, setup scripts, seed data), verify the environment still comes up from scratch, or say plainly that you couldn't verify it.
- If you discover the build is already broken by your change, fixing it is now your top priority — ahead of the next feature, ahead of cleanup, ahead of everything.
- If you cannot fix the breakage, say so loudly: what's broken, what caused it, and the revert that restores green. Never bury a known break in a success summary.
- Renamed or deleted scripts, make targets, and npm scripts count: search for what calls them (CI configs, docs, other scripts) before assuming nothing does.

**Red flags that you're about to violate this:**
- "My tests pass; the full build is CI's job to check."
- "That compile error is in a module I barely touched, probably pre-existing."
- "I'll mention the broken script in passing and keep going."
- "Someone will notice and fix the dev container."
- "The build failure looks flaky, moving on."

---

## Why It Works

1. **It redefines "done" to include the commons** — the build and dev environment are shared infrastructure, and folding them into completion criteria is the only way the AI's optimization includes them.
2. **It exploits the context window** — the author of a break is exponentially cheaper as the fixer than whoever discovers it later, so the rule pins the fix to the moment of maximum context.
3. **It bans the buried disclosure** — a break mentioned mid-summary reads as success; the rule forces breakage to be the headline or fixed.
4. **It makes deletion a search problem** — renamed scripts break CI silently, and "find the callers first" catches the references the AI can't see from the diff.

## Origin

An assistant restructured a project's npm scripts as part of a cleanup, renaming `test:integration` to `test:int` for consistency. Its own checks passed. The CI pipeline, three deploy scripts, and a nightly job all called the old name. The team lost a full day: CI red for everyone, two engineers bisecting in parallel, a release pushed back — all for a rename whose entire benefit was four saved characters.
