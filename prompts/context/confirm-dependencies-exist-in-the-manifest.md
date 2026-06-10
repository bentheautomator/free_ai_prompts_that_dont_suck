---
title: Confirm Dependencies Exist in the Manifest
slug: confirm-dependencies-exist-in-the-manifest
category: context
tags: [universal, assumptions, verification]
works_with: all
severity: high
one_liner: "AI importing lodash because every project has lodash — except this one"
---

# Confirm Dependencies Exist in the Manifest

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from importing packages the project never installed, just because most projects have them.

**[Copy-paste ready version](../../install/confirm-dependencies-exist-in-the-manifest.md)** — just the instruction block, no explanation.

## The Problem

Some packages feel like part of the language: lodash, axios, requests, moment, classnames. The AI imports them on reflex — `import _ from 'lodash'` — without checking whether this project ever installed them. Maybe the team deliberately avoids lodash (bundle size), uses the platform `fetch` instead of axios, banned moment years ago, or simply never needed the package. The import fails at build time if you're lucky; in looser setups it fails at runtime, in production, on the one code path that exercises it.

There's a deliberate-decision layer underneath the inconvenience. Lean dependency policies exist on purpose: security teams audit every new package, bundle budgets are real, and "we use date-fns, not moment" is a decision someone fought for. An AI that assumes the common package both breaks the build and tramples the policy. Worse is the AI's favorite self-fix: silently adding the package to `package.json` to make its own import work — now a dependency entered the project because the AI assumed it was already there, which is supply-chain decision-making by autocomplete.

The check is one grep into one file: is the package in the manifest? If not, the project told you something.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Confirm Dependencies Exist in the Manifest

NEVER import a third-party package without confirming it's in this project's manifest. "Every project has lodash" is a statistic, not a dependency declaration — and missing-but-common packages are often missing *on purpose*.

An assumed import breaks the build at best; at worst you "fix" it by silently installing a package the team deliberately excluded.

**Before importing any third-party package:**
- Check the manifest: `package.json` dependencies/devDependencies, `pyproject.toml`/`requirements.txt`, `go.mod`, `Cargo.toml`, `Gemfile` — a grep for the package name settles it in seconds
- Found it? Also note where: importing a devDependency from production code is its own failure (works locally, crashes in the production build)
- Not found? Check what the project uses instead — grep existing code for how it does HTTP, dates, utilities; absence of axios usually means presence of `fetch` or a wrapper
- Prefer the in-repo alternative: the project's existing utility, the stdlib, or a small local implementation — matching what neighbors do
- If a new dependency is genuinely warranted, propose it as an explicit decision ("this needs X, which isn't installed — add it?") rather than installing it as a side effect of your import
- Transitive presence doesn't count: a package in the lockfile via some other dependency is not yours to import — it can vanish on any upgrade

**Red flags that you're about to violate this:**
- "I'll just use lodash for this..."
- "axios is definitely installed, it always is..."
- "It's not in package.json? I'll add it real quick..."
- "It's in node_modules, so it's available..." — transitively, until it isn't
- "requests is basically part of Python..."
- Writing an import statement for a package you haven't seen in this project's manifest or existing imports

---

## Why It Works

1. **It recasts absence as information.** "Missing on purpose" flips the AI's frame from "this project forgot lodash" to "this project decided about lodash" — making the missing package a convention to respect, not a gap to fill.

2. **It blocks the silent-install reflex.** The worst outcome isn't the broken import; it's the AI resolving its own error by adding the dependency. Requiring an explicit proposal restores the human decision the reflex bypasses.

3. **It covers the two subtle placements.** DevDependency-in-prod-code and transitive-in-lockfile both pass naive "is it available?" checks and both blow up later; naming them upgrades the check from "importable" to "correctly declared."

4. **It routes to in-repo alternatives first.** Grepping for how the project already does HTTP or dates usually finds the sanctioned answer — turning a blocked import into a convention discovery.

## Origin

An AI added retry logic to a checkout service using a well-known HTTP client — not installed; the team used the platform fetch behind a thin wrapper with tracing built in. The AI helpfully installed the client to fix its own import. The dependency sailed through review inside a 200-line diff, bypassed the team's tracing wrapper, and for six weeks a slice of checkout traffic was invisible to observability. The security audit that finally caught the unvetted package asked a reasonable question nobody could answer: "who chose this?"
