---
title: Install Into the Correct Workspace
slug: install-into-the-correct-workspace
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: high
one_liner: "Stops monorepo installs landing in the root or wrong package's manifest"
---

# Install Into the Correct Workspace

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding monorepo dependencies to whatever manifest is nearest instead of the package that needs them.

**[Copy-paste ready version](../../install/install-into-the-correct-workspace.md)** — just the instruction block, no explanation.

## The Problem

Monorepos have many manifests, and an install command lands in whichever one governs the current directory. AI assistants, often parked at the repo root, run `npm install pino` and add a logging library to the workspace root — a manifest that exists to orchestrate the workspaces, not to own application dependencies. Or they're standing in `packages/web` while fixing code in `packages/api`, and the API's new dependency lands in the web app's manifest. Hoisting then makes everything resolve anyway, so the mistake is invisible until something de-hoists it.

Root-installed dependencies are the monorepo's slow rot: the dependency works everywhere by hoisting accident, so each package that uses it never declares it, and the day the repo moves to pnpm's strict layout, or a package gets extracted to its own repo, or the build starts pruning per-package dependencies for deployment — dozens of undeclared usages surface at once. Wrong-workspace installs have a sharper failure: the package that actually imports the library doesn't have it, which breaks exactly when that package is built or deployed in isolation, i.e., in the environment least convenient for debugging.

A worse variant: in npm workspaces, running plain `npm install` inside a workspace subdirectory can generate a nested `node_modules` and even a stray lockfile, fracturing the single-resolution model the workspace tooling depends on.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Install Into the Correct Workspace

ALWAYS add a dependency to the manifest of the workspace whose code imports it. In a monorepo, "the install command succeeded" says nothing about whether the dependency landed where it belongs.

- Identify the owning workspace first: which package's source files will import this? That package's manifest gets the entry — not the root, not the workspace you happen to be standing in.
- Use workspace-targeted commands from the repo root: `npm install <pkg> -w packages/api`, `pnpm add <pkg> --filter @scope/api`, `yarn workspace @scope/api add <pkg>`. These work regardless of current directory and name the target explicitly.
- The root manifest is for repo-wide tooling only — the test runner, linter, build orchestrator shared by all packages. Application dependencies (HTTP clients, ORMs, loggers, UI libraries) in the root manifest are misfiled even if everything resolves.
- If the same library is needed by several packages, declare it in each package that imports it. Hoisting may store one physical copy; the manifests must still tell the truth per package.
- Never run a bare `npm install` from inside a workspace subdirectory in ways that spawn a nested `node_modules` or extra lockfile. Install from the root with workspace flags, and if a stray nested lockfile appears, remove it before committing.
- After installing, verify placement: check that the diff touched the intended package's manifest, not the root's.

**Red flags that you're about to violate this:**
- "I'm at the repo root, so npm install here is simplest."
- "It resolves from every package anyway thanks to hoisting."
- "I'll add it to the root so all the packages can share it."
- "The install worked from this directory, so the location is fine."
- "Which workspace owns this file doesn't change the command."

---

## Why It Works

1. **It defines ownership by imports, not by current directory** — the AI's placement heuristic is literally "where am I standing," and the rule replaces it with a question about the code.
2. **It makes workspace-targeted commands the default form**, which decouples correctness from the AI's working directory entirely; the flag names the destination, so standing in the wrong place stops mattering.
3. **It explains why hoisting success is false evidence**, preempting the strongest counterargument the AI will generate ("but it resolves everywhere") with the de-hoisting scenarios where the debt comes due.
4. **It adds a diff-placement check at the end**, catching the failure after the fact at the cost of one glance — which matters because the wrong-manifest mistake produces zero errors at install time.

## Origin

A monorepo's API package gained a queue-client dependency that an assistant installed from the repo root, into the root manifest. Everything worked for months — hoisting served the package to everyone. Then the platform team containerized each workspace separately with per-package dependency pruning, and the API image built green but crashed on startup: the queue client wasn't in the API's manifest, so it wasn't in the API's image. The outage hit during the containerization cutover, the worst possible time to debug "module not found" for a module everyone could see in the repo.
