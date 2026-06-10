---
title: Check Config Before Assuming Framework Defaults
slug: check-config-before-assuming-framework-defaults
category: context
tags: [universal, config, assumptions]
works_with: all
severity: high
one_liner: "AI assuming port 3000 and default paths in a project that overrode both"
---

# Check Config Before Assuming Framework Defaults

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from treating a framework's out-of-the-box defaults as facts about a configured project.

**[Copy-paste ready version](../../install/check-config-before-assuming-framework-defaults.md)** — just the instruction block, no explanation.

## The Problem

Frameworks ship with defaults, and the AI knows them cold: the dev server is on port 3000, builds go to `dist/`, routes live where the scaffold put them, the base URL is `/`. But real projects override defaults — that's what the config file is for. The AI that "knows" the framework keeps answering from the scaffold while the project has moved its output directory, changed its port, customized its source root, and rewired its routing convention.

The result is advice for a project that doesn't exist. Debugging steps that say "open localhost:3000" when the config says 8080. New route files created where the default convention puts them, ignored by a router configured differently. Build artifacts referenced at `dist/` while CI deploys from `build/`. Each mistake is small, but they share a root cause: the AI treated "what the framework does by default" as "what this project does," skipping the one file that records every deliberate deviation.

A framework default is a fact about the framework. The config file is the fact about the project. When they disagree, only one of them is right.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Config Before Assuming Framework Defaults

NEVER assume a framework's default behavior applies to this project without checking its config files. Defaults are what the project does when nobody decided otherwise — config files are the record of everyone who decided otherwise.

Answering from defaults in a configured project gives directions to a building that's been renovated.

**Before relying on any framework default:**
- Read the framework's config file(s) first: `next.config.*`, `vite.config.*`, `angular.json`, `settings.py`, `application.yml`, `webpack.config.*`, framework sections in `package.json` or `pyproject.toml`
- Verify the specific default you're about to lean on — port, output directory, source root, base path, routing convention, environment handling — rather than skimming for vibes
- Check for environment-specific overrides: `.env` files, per-environment configs, CLI flags baked into the `dev`/`build` scripts in `package.json` or the Makefile
- When the config customizes one thing, raise your suspicion about everything else — teams that override a port also override directories
- State which config value you found when it drives your answer ("your vite.config sets port 5180, so...") so a wrong read is catchable

**Red flags that you're about to violate this:**
- "By default this framework serves on..."
- "The build output will be in dist/, as usual..."
- "Routes go in this directory — that's the convention..."
- "They probably haven't changed the defaults..."
- "The config file is mostly boilerplate, no need to read it..."
- Citing any port, path, or directory you didn't see in a config file or script this session

---

## Why It Works

1. **It reframes what a config file is.** "The record of everyone who decided otherwise" makes skipping it feel like ignoring the project's decision log, not skipping boilerplate.

2. **It demands the specific lookup, not a skim.** "Verify the default you're about to lean on" turns a vague read-the-config suggestion into a targeted check tied to the claim being made.

3. **It uses one override as evidence of more.** Customization clusters; teaching the AI that a changed port predicts a changed output directory converts a single observation into appropriately broader caution.

4. **It makes claims auditable.** Requiring the AI to cite the config value it found means a misread surfaces immediately, instead of hiding inside a confident instruction.

## Origin

A developer reported their app changes weren't showing up. The AI walked them through a careful debugging sequence centered on `localhost:3000` — cache clearing, hard reloads, dev-server restarts. Forty minutes in, someone opened `vite.config.ts`: the dev server ran on 4400, and port 3000 belonged to a stale Docker container from a different project, dutifully serving an app nobody was editing. The debugging session had been debugging the wrong application the entire time.
