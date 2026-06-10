---
title: Read the Changelog Before Major Version Bumps
slug: read-the-changelog-before-major-version-bumps
category: dependencies
tags: [universal, dependencies, versions]
works_with: all
severity: high
one_liner: "Stops casual major upgrades made without reading the breaking changes"
---

# Read the Changelog Before Major Version Bumps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from jumping a dependency across a major version to fix a warning, without ever looking at the breaking changes.

**[Copy-paste ready version](../../install/read-the-changelog-before-major-version-bumps.md)** — just the instruction block, no explanation.

## The Problem

A deprecation warning shows up in the install output, and the AI's response is mechanical: upgrade the package. If the fix happens to live on the other side of a major version — say, going from `eslint@8` to `eslint@9`, or `express@4` to `express@5` — the assistant bumps it anyway, runs whatever tests are handy, and declares the warning resolved. The major version number, which exists specifically to say "this release breaks things," gets treated as just a bigger number.

Major versions remove APIs, change defaults, drop runtime support, and restructure configuration. ESLint 9 replaced the entire config file format. Express 5 changed how route handlers deal with rejected promises. Tailwind 4 rewrote configuration from JavaScript into CSS. An assistant that bumps the version without reading the migration guide leaves the project half-migrated: it compiles, maybe even passes the visible tests, and fails in the exact areas the changelog warned about.

The behavior comes from how upgrades look in isolation. `npm install eslint@latest` is one command, the warning goes away, and the breaking changes are documented somewhere the assistant never looked. The semver contract — major means breaking — is knowledge the model has, but nothing in the task forces it to act on it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read the Changelog Before Major Version Bumps

NEVER upgrade a dependency across a major version boundary without first reading its changelog or migration guide for that major. A major version bump is a documented set of breaking changes, not a bigger number.

- Before any major bump, find the breaking-changes list (CHANGELOG.md, GitHub releases page, migration guide) and enumerate which entries touch this codebase. If you cannot access the changelog, say so and stop instead of upgrading blind.
- A deprecation warning is not an upgrade mandate. The supported response is usually a small code change on the current major, not a version jump. Fix the deprecated usage first; upgrade as a separate, deliberate task.
- When the user asks for the upgrade itself, do it as a migration: bump the version, apply every relevant change from the migration guide (config format, renamed APIs, changed defaults), and list which breaking changes you handled and which you verified don't apply.
- Never bundle a major upgrade into an unrelated task. "Fix the failing test" must not quietly include "and also move to webpack 6."
- Check the new major's minimum runtime requirements (Node version, Python version) against what the project and its CI actually run.

**Red flags that you're about to violate this:**
- "Upgrading to the latest version should resolve this warning."
- "The tests pass after the bump, so the breaking changes must not affect us."
- "Majors are mostly marketing; the API is probably the same."
- "I'll bump it now and we can deal with any issues if they come up."
- "The deprecation message says this is removed in v9, so I'll just install v9."

---

## Why It Works

1. **It restores the meaning of the version number.** The AI knows what semver promises but treats the major digit as cosmetic under task pressure; the rule makes "major = documented breakage" operational.
2. **It decouples the warning from the upgrade.** Most deprecation warnings are fixable on the current major, and naming that path removes the false dichotomy of "upgrade or live with the warning."
3. **It demands an enumerated migration**, not a version edit. Listing which breaking changes apply forces the changelog read to actually happen, instead of being claimed.
4. **It blocks the scope smuggle** — major upgrades hidden inside unrelated tasks are the variant that reaches production unreviewed.

## Origin

A team asked their assistant to silence a noisy deprecation warning from their linter. The assistant upgraded the linter two majors, which changed the config file format entirely; the old config was silently ignored, so the linter ran with defaults and passed everything. Six weeks of commits landed with effectively no linting before someone noticed rules that "used to fire" never did. The original warning would have been fixed by changing one config key on the old major.
