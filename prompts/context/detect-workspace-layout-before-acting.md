---
title: Detect Workspace Layout Before Acting
slug: detect-workspace-layout-before-acting
category: context
tags: [universal, tooling, assumptions]
works_with: all
severity: high
one_liner: "AI treating a monorepo as a single package and installing at the wrong root"
---

# Detect Workspace Layout Before Acting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from running single-package commands in a monorepo, or targeting the wrong package when there are forty.

**[Copy-paste ready version](../../install/detect-workspace-layout-before-acting.md)** — just the instruction block, no explanation.

## The Problem

Monorepos break every assumption the AI carries from single-package projects. "Add a dependency" now has a destination question: which package? Run `pnpm add` at the root and you've polluted the workspace root with a dependency one package needed. "Run the tests" means which package's tests, invoked how — `pnpm --filter @app/api test`, `turbo run test`, `nx test api` — not a bare `npm test` that either fails or runs forty packages' suites for an hour. Imports between packages go through workspace protocol and package names, not `../../other-package/src` relative paths that happen to resolve locally and explode in CI.

The AI defaults to single-package mental models because most training examples are single packages. So it installs at whatever directory it happens to be in, greps only the package it first landed in and declares code "not found," edits one package's copy of a shared config, or adds a cross-package import as a relative path. Each mistake is invisible locally and expensive later — workspace dependency graphs and build orchestrators (Turborepo, Nx, Lerna, Bazel, pnpm workspaces, cargo workspaces, go workspaces) all have opinions, and they enforce them at the worst possible time.

One look at the root answers everything: `pnpm-workspace.yaml`, a `workspaces` field, `turbo.json`, `nx.json`, `Cargo.toml [workspace]`, `go.work`.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Detect Workspace Layout Before Acting

ALWAYS determine whether you're in a monorepo — and which package you're operating on — before installing, running, importing, or searching. Single-package instincts applied to a workspace put dependencies at the wrong root, run the wrong tests, and create imports that only work by accident.

In a workspace, every command has an implicit "which package?" parameter, and your default answer is wrong.

**Before acting in any repo:**
- Check the root for workspace markers: `pnpm-workspace.yaml`, `workspaces` in `package.json`, `lerna.json`, `turbo.json`, `nx.json`, `go.work`, `Cargo.toml` with `[workspace]`, `packages/`/`apps/` directories
- Install dependencies into the specific package that needs them (`pnpm --filter <pkg> add`, `npm i -w <pkg>`, `cargo add -p <pkg>`) — root installs are for genuinely shared tooling only
- Run tasks the way the orchestrator expects: through the workspace tool's filter/scope syntax or the root scripts that wrap it, not by cd-ing around and running bare commands
- Write cross-package imports via package names and workspace protocol, never relative paths that climb out of the package — check how existing cross-package imports do it
- Scope searches deliberately: when looking for code, search the whole workspace; when editing config, know whether the file is root-level (shared) or package-level (local), because each package may have its own
- When the target package is ambiguous from the user's request, ask — "the API package or the worker?" is one question; unwinding a wrong-package change is a diff

**Red flags that you're about to violate this:**
- "I'll install it here at the root, it'll be available everywhere..."
- "npm test from wherever I am should work..."
- "I'll import it with a relative path, it resolves fine..."
- "There's only one tsconfig that matters..."
- "I searched the package and the function doesn't exist in this repo..."
- Running an install command without knowing which package.json it will modify

---

## Why It Works

1. **It adds the missing parameter.** "Every command has an implicit which-package" gives the AI a slot to fill that its single-package mental model doesn't have — making the ambiguity visible before the command runs.

2. **It anchors detection to concrete markers.** A finite, checkable list of root files turns "is this a monorepo?" from a vibe into a ten-second test with a definitive answer.

3. **It separates root-level from package-level config.** Many workspace disasters are edits to the wrong layer of a layered config; naming that distinction converts a class of subtle errors into a known check.

4. **It prices the question correctly.** "One question vs. unwinding a diff" justifies asking about ambiguous targets, which AIs otherwise avoid because asking feels like incompetence.

## Origin

Asked to add a date library to a web app inside a 30-package workspace, an AI ran the install from the repo root. The dependency landed in the root `package.json`, hoisting changed, and two other packages that had been accidentally relying on a phantom version of a different library stopped building — but only in CI, which used frozen lockfiles. The web app change itself was three lines; the archaeology to explain why two unrelated packages broke took the better part of two days.
