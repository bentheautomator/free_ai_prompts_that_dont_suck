---
title: Verify Import Aliases Against Config
slug: verify-import-aliases-against-config
category: context
tags: [universal, config, conventions]
works_with: all
severity: medium
one_liner: "AI writing @/components imports in a project that never configured the @ alias"
---

# Verify Import Aliases Against Config

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing path-alias imports that this project's tsconfig and bundler never defined.

**[Copy-paste ready version](../../install/verify-import-aliases-against-config.md)** — just the instruction block, no explanation.

## The Problem

`import { Button } from '@/components/Button'` is muscle memory from a thousand scaffolds — and it only works if *this* project mapped `@/` in `tsconfig.json` paths and mirrored it in the bundler config. Plenty of projects didn't. Plenty configured something else: `~/` for source root, `@app/` and `@shared/` per layer, `#` subpath imports from `package.json`, or no aliases at all, by explicit team decision. The AI that writes its habitual alias gets `Cannot find module '@/components/Button'` — or writes relative imports into a codebase where everything else uses the alias, fragmenting the convention.

The mirror-config problem makes this worse than a simple lookup. Aliases must agree across every tool that resolves modules: TypeScript paths, the bundler (vite/webpack aliases), the test runner (Vitest alias config, Jest `moduleNameMapper`), sometimes ESLint's import resolver. An AI that "fixes" a missing alias by adding it to tsconfig alone creates code that typechecks but won't build, or builds but won't test — a half-configured alias is more confusing than none.

The whole question is answered by two files the AI can read in ten seconds: the tsconfig `paths` block and the bundler config.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Verify Import Aliases Against Config

NEVER write an aliased import (`@/`, `~/`, `#app/`, `@shared/`) without confirming the alias is configured in this project — and never invent one because most projects you've seen have it. Aliases are per-project config, not a language feature.

A habitual `@/` in an alias-less project is an instant resolution error; the reverse — relative paths in an aliased codebase — quietly fragments the import convention.

**Before writing imports:**
- Check what's configured: `compilerOptions.paths` in `tsconfig.json`/`jsconfig.json`, bundler alias config (`vite.config.*` `resolve.alias`, webpack `resolve.alias`), `imports` field in `package.json` for `#` subpaths
- Check what's practiced: open existing files near your edit and use the import style they use — config says what's possible, neighbors say what's conventional
- Note where each alias points: `@/` maps to `src/` in some projects, project root in others, `app/` in others — the prefix alone doesn't tell you the target
- Respect boundaries encoded in aliases: in monorepos, `@scope/package` imports are package boundaries — don't bypass them with relative paths that climb between packages
- If asked to *add* an alias, update every resolver the project uses: tsconfig paths, bundler alias, test runner alias/`moduleNameMapper` — a partially-registered alias typechecks but fails at build or test
- When config and practice disagree (alias configured, nobody uses it), follow practice and mention the discrepancy

**Red flags that you're about to violate this:**
- "I'll import it with @/, that's standard..."
- "Every Vite project has the src alias set up..."
- "@/ obviously points to src here..."
- "I'll add the alias to tsconfig, that's the only place it matters..."
- "Relative path is fine even though every neighbor uses ~/ ..."
- Writing an alias prefix you have not seen in either this project's config or its existing imports

---

## Why It Works

1. **It corrects the category error.** The AI treats `@/` like syntax because scaffolds made it ubiquitous; stating it's per-project config reframes every aliased import as a claim about two files it can check.

2. **It separates configured from conventional.** "Config says possible, neighbors say conventional" handles both failure directions — inventing aliases and ignoring established ones — with one rule.

3. **It makes the mirror-config requirement explicit.** The tsconfig-only "fix" is this failure's nastiest variant because it half-works; enumerating every resolver turns a subtle trap into a checklist.

4. **It flags target ambiguity.** Knowing `@/` exists isn't knowing where it points; requiring the mapping check prevents right-alias-wrong-directory imports that resolve to the wrong module or nothing.

## Origin

A developer asked for a new settings panel in a mid-sized React app. The AI generated eight files, all importing via `@/` — an alias the project had never configured, since the team had standardized on strict relative imports two years earlier and even had a lint rule about it. Nothing resolved, the lint run produced a wall of errors, and the "quick panel" spent its first hour being find-and-replaced into compliance with a convention the AI could have learned from literally any file in the repo.
