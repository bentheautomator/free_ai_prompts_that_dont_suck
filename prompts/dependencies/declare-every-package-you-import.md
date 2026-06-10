---
title: Declare Every Package You Import
slug: declare-every-package-you-import
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: high
one_liner: "Stops importing transitive deps that vanish when a parent package updates"
---

# Declare Every Package You Import

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from importing packages the project never declared, which resolve today by hoisting accident and vanish later.

**[Copy-paste ready version](../../install/declare-every-package-you-import.md)** — just the instruction block, no explanation.

## The Problem

In an npm project with flat hoisting, `node_modules` contains far more packages than `package.json` declares — every transitive dependency of every dependency, physically present and importable. An AI assistant writing code will `import ms from 'ms'` or `require('semver')`, the import resolves, the code runs, and nothing anywhere records that the project now depends on it. The project just acquired a load-bearing dependency that exists only as a side effect of some other package's internals.

These phantom dependencies detonate on a delay. The parent package that was pulling in `ms` refactors it away in a patch release, and suddenly an unrelated `npm install` breaks your imports — in code nobody touched, for reasons the diff can't explain. Version is also uncontrolled the whole time: you get whatever version the parent wanted, which can change under any lockfile update without anyone agreeing to it. pnpm's strict layout exists specifically to make these imports fail fast, which is why code with phantom deps "mysteriously" breaks when a repo migrates to pnpm.

Assistants create phantom deps because their feedback signal is "does the import resolve," and hoisting makes the wrong answer resolve. The manifest — the actual statement of what the project depends on — never gets consulted when the import already works.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Declare Every Package You Import

NEVER import a package that isn't declared in the project's own manifest. "The import resolves" is not evidence of a dependency — in hoisted `node_modules` layouts, hundreds of undeclared transitive packages resolve by accident, and any of them can vanish or change version when a parent package updates.

- Before writing an import for a package, check it's in this project's `package.json` (`dependencies` or, for test/build code, `devDependencies`). In a monorepo, check the manifest of the specific workspace the file belongs to — a dependency declared in a sibling package doesn't count.
- If it's not declared but you need it, install it properly (`npm install <pkg>` / `pnpm add <pkg>`) so manifest and lockfile record it at a version the project controls.
- Don't import from a dependency's internals either (`lodash/internal/...`, deep paths into another package's `dist/`) — undeclared and unexported paths are both promises nobody made to you.
- The same rule outside JS: don't `import` a Python package just because it arrived as a transitive dependency of something in requirements. Declare what you use.
- When touching existing code, treat an undeclared import you find as a latent break worth mentioning — it will fail on the next dependency shuffle or a pnpm migration.

**Red flags that you're about to violate this:**
- "The import works, so the package is available."
- "It's already in node_modules; installing it again would be redundant."
- "Some other dependency brings it in, so it'll always be there."
- "Adding it to package.json is bookkeeping; the code runs fine."
- "It resolves in this workspace, so it must be declared somewhere."

---

## Why It Works

1. **It discredits the AI's resolution-based evidence.** "It imports fine" is the entire basis for the failure; the rule explains why that signal lies under hoisting, which is more durable than a bare prohibition.
2. **It makes the manifest the source of truth for "available,"** a one-file check that cleanly separates declared dependencies from hoisting accidents.
3. **It covers the monorepo variant** — sibling-workspace leakage — which is the form most likely to pass local testing and fail in isolation or CI.
4. **It extends to deep-path imports**, the adjacent failure with the same root cause: relying on package internals that no contract protects.

## Origin

A utilities module written by an assistant imported a tiny duration-parsing package that the project had never declared — it arrived via the web framework's transitive tree. A year later the framework's patch release dropped that internal dependency, and `npm install` on a routine morning broke imports in eleven files across the app. The diff that "caused" the outage was a lockfile bump of an unrelated framework patch, which is why the first three hours of debugging went toward the framework instead of the imports.
