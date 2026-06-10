---
title: Check Runtime Version Files First
slug: check-runtime-version-files-first
category: context
tags: [universal, versions, environment]
works_with: all
severity: high
one_liner: "AI writing Python 3.12 syntax for a service pinned to 3.8 by its Dockerfile"
---

# Check Runtime Version Files First

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing code for the runtime version it likes instead of the one the project pins.

**[Copy-paste ready version](../../install/check-runtime-version-files-first.md)** — just the instruction block, no explanation.

## The Problem

Projects pin their runtimes deliberately: `.nvmrc`, `.node-version`, `engines` in `package.json`, `.python-version`, `requires-python` in `pyproject.toml`, `go.mod`'s go directive, `.ruby-version`, the `FROM python:3.8-slim` line in the Dockerfile. The AI writes for whatever version feels current — match statements and walrus-flavored generics for a Python 3.8 service, `structuredClone` and top-level await for a Node 14 Lambda, generics for a Go version that predates them.

Sometimes the mismatch breaks immediately and locally, which is the good outcome. The bad outcome is environment skew: the developer's machine runs a newer runtime than production, so the code works in every local test and dies on deploy with a `SyntaxError` — the kind of failure that pages someone. Containerized and serverless targets make this routine, because the pinned production runtime is exactly the file (Dockerfile, serverless config) the AI didn't read.

There's also the standard-library version of this failure: not new syntax, but new stdlib — `tomllib` (3.11+), `Array.prototype.at` (Node 16.6+), `fetch` as a global (Node 18+). The code parses fine on the old runtime and crashes at the call site, which makes it sneakier than a syntax error.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Runtime Version Files First

NEVER write code that depends on runtime version features without confirming the version this project actually pins. The version in your head is "recent"; the version in production is whatever the Dockerfile says, and the gap between them is a deploy-time crash.

Local dev often runs newer runtimes than production, so version-mismatched code passes every local test and fails exactly once it matters.

**Before writing version-sensitive code:**
- Check the pins: `.nvmrc`, `.node-version`, `engines` in `package.json`, `.python-version`, `requires-python`, `.ruby-version`, `.tool-versions` (asdf/mise), `go.mod`, `rust-toolchain.toml`
- Check the deployment truth, which outranks local pins: Dockerfile `FROM` lines, serverless runtime declarations, CI setup steps (`setup-node`/`setup-python` versions), buildpack configs
- Know which features have version floors and check before using them: syntax (match statements, optional chaining era, generics in Go), and stdlib additions (`tomllib`, global `fetch`, `structuredClone`)
- Mind the transpilation question in JS/TS: tsconfig `target` and browserslist define what you can *emit*, not just what you can write — and runtime stdlib still isn't transpiled in
- When pins conflict (Dockerfile says 3.8, `.python-version` says 3.12), flag the skew — it's a latent incident, and your code needs to satisfy the lowest one that runs in production
- No pin found anywhere? Ask, or target a conservative version and say which you assumed

**Red flags that you're about to violate this:**
- "Modern syntax is fine, everyone's on a current version..."
- "This stdlib function has been around for ages..." — has it, on their runtime?
- "It runs on my reasoning about the latest docs..."
- "The Dockerfile is deployment stuff, not relevant to the code..."
- "Surely this Lambda isn't still on an old Node..."
- Using a feature whose minimum version you couldn't state for a runtime you haven't checked

---

## Why It Works

1. **It names the local/prod skew explicitly.** "Passes every local test, fails on deploy" is the property that makes this failure expensive; once the AI knows local success proves nothing, the version check stops feeling optional.

2. **It ranks deployment files above local pins.** Dockerfiles and serverless configs are where production's truth lives, and they're precisely the files the AI skips as "ops stuff." The explicit ranking redirects attention.

3. **It splits syntax from stdlib.** Syntax errors fail at parse; missing stdlib fails at the call site, later and sneakier. Treating them as separate checks prevents "it parses" from standing in for "it runs."

4. **It turns pin conflicts into findings.** Skewed version files are a pre-existing hazard; requiring the AI to flag them converts an excuse ("the files disagreed") into delivered value.

## Origin

An AI added a small parsing improvement to a data pipeline using a stdlib module introduced two minor versions after the runtime in the service's Dockerfile. Local dev was on the newer runtime: tests green, review clean, merge. The nightly batch job crashed at 2 a.m. on the import line, the on-call engineer rolled back a deploy that contained four other teams' changes, and the postmortem traced it all to a version pin that was written in the second line of the Dockerfile.
