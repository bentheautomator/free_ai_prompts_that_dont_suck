---
title: Check Defined Scripts Before Running Commands
slug: check-defined-scripts-before-running-commands
category: context
tags: [universal, tooling, conventions]
works_with: all
severity: high
one_liner: "AI running npx jest directly when the repo's make test does required setup"
---

# Check Defined Scripts Before Running Commands

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from inventing build/test/run commands when the project defines its own.

**[Copy-paste ready version](../../install/check-defined-scripts-before-running-commands.md)** — just the instruction block, no explanation.

## The Problem

The project defines `"test": "vitest run --config vitest.workspace.ts --silent"` in `package.json`. The AI runs `npx vitest` — close, but missing the workspace config, so half the suites don't run and the AI reports "all tests pass." Or the repo has a `Makefile` where `make test` spins up a database container first, and the AI's raw `pytest` invocation fails with connection errors the AI then "fixes" by mocking things that didn't need mocking.

Projects encode their operational knowledge in script definitions: `package.json` scripts, Makefiles, `justfile`s, `tasks.py`, `composer.json` scripts, gradle tasks. These aren't aliases for convenience — they carry flags, env vars, pre-steps, and orderings that the bare command lacks. The AI that types the textbook command instead is discarding the project's accumulated fixes for every way the bare command goes wrong. The textbook command is what the script *wraps*, not what it equals.

The failure has a sneaky second act: when the invented command produces wrong results — partial test runs, builds missing a codegen step — the AI treats those results as facts about the project and starts "fixing" problems that exist only in its own wrongly-invoked world.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Defined Scripts Before Running Commands

ALWAYS check what build, test, lint, and run commands the project defines before inventing your own. Defined scripts carry flags, environment setup, and pre-steps that the bare tool invocation lacks — they are the project's operational knowledge, encoded.

A bypassed script doesn't just fail; it half-works, producing partial test runs and incomplete builds that you'll then misread as facts about the code.

**Before running any build/test/lint/run command:**
- Check the script registries in order: `package.json` `scripts`, `Makefile`, `justfile`, `Taskfile.yml`, `tox.ini`/`noxfile.py`, `composer.json`, gradle/maven tasks, repo README's command section
- Run the defined script, with the project's package manager, rather than the underlying tool directly — `pnpm test`, not `npx vitest`
- Read what the script actually does before running it, especially for anything beyond test/build — scripts named `clean` or `reset` can be destructive
- If you need different behavior (one test file, watch mode), derive your variation from the defined script's flags and config, keeping its setup intact
- When no script exists for what you need, check CI workflows (`.github/workflows/`) for how automation invokes the tool — CI is the project's executable documentation
- If your invented command fails or gives surprising results, suspect your invocation before suspecting the code

**Red flags that you're about to violate this:**
- "I'll just run the test command directly..."
- "npx jest does the same thing as their script..."
- "The Makefile is probably just a wrapper, skipping it..."
- "I don't need their flags for a quick check..."
- "The tests fail with connection errors — must be broken tests..." — after a raw invocation
- Running a tool whose project-defined wrapper you never looked for

---

## Why It Works

1. **It reframes scripts as knowledge, not aliases.** The AI bypasses scripts because they look like shorthand for the command it already knows. "Encoded operational knowledge — what the script wraps, not what it equals" explains why the wrapper is the real interface.

2. **It names the half-works hazard.** Total failure self-corrects; partial test runs reported as green don't. Highlighting the misleading-success mode justifies checking even when the bare command "worked."

3. **It redirects blame on surprise.** "Suspect your invocation before the code" intercepts the second-act failure where the AI fixes phantom problems created by its own wrong command.

4. **It designates CI as fallback documentation.** When scripts are missing, workflows show the blessed invocation — giving the AI a verified source instead of a license to improvise.

## Origin

A repo's `make test` ran a codegen step before the suite, because generated clients had to match the schema. An AI ran the test binary directly, got fifty failures about missing types, diagnosed "broken generated code," and spent the session hand-writing the missing types — duplicating what codegen produced, except subtly outdated. The hand-written types shadowed the generated ones for two sprints, and the schema drift they concealed eventually broke a downstream consumer that trusted the contract.
