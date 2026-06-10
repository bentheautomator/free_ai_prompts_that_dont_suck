---
title: Check Manifest Versions Before Advising
slug: check-manifest-versions-before-advising
category: context
tags: [universal, versions, assumptions]
works_with: all
severity: high
one_liner: "AI giving React 19 advice to a project pinned to React 16"
---

# Check Manifest Versions Before Advising

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from assuming a project runs the latest major version of its dependencies.

**[Copy-paste ready version](../../install/check-manifest-versions-before-advising.md)** — just the instruction block, no explanation.

## The Problem

When an AI knows a library, it knows the version it saw most — usually the latest one prominent in training data. So advice arrives calibrated to that version: "use the App Router," "this hook handles it now," "that option was removed, use the new one." Meanwhile `package.json` says the project is on a major version from three years ago, where the recommended API doesn't exist yet and the "removed" option is still the only way.

Version-blind advice fails in both directions. Recommending new APIs to an old codebase produces code that won't compile or upgrade suggestions nobody asked for. Recommending old patterns to a new codebase produces deprecated approaches that linters flag and maintainers reject. Either way, the user pays in confusion: the advice sounds authoritative, references real things, and is wrong for the only project that matters.

The project declares every version it depends on, in one file, at the root. `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile.lock`, `pom.xml` — version-checking is a ten-second read that turns generic library knowledge into project-specific advice.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Manifest Versions Before Advising

NEVER give version-sensitive advice about a dependency without first reading its version from the project's manifest or lockfile. Your knowledge of a library defaults to one version — usually the newest — and this project is probably not on it.

Advice calibrated to the wrong major version references APIs that don't exist here, patterns that were removed, or migrations the team already rejected.

**Before discussing or using any dependency:**
- Read the declared version: `package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`/`build.gradle`
- Prefer the lockfile's resolved version when ranges are loose — `^4.0.0` may have resolved to 4.2 or 4.17, and the difference can matter
- Frame advice for the version found: if the project is on v3, give v3 answers, even if v5 does it better — mention the upgrade only as a labeled aside
- Watch for breaking-change boundaries you know about (router rewrites, config format changes, renamed exports) and check which side of the boundary the project sits on
- If a version is too old or too new for your knowledge to be reliable, say that, and check the repo's docs or changelogs before guessing

**Red flags that you're about to violate this:**
- "In the current version of this library..."
- "They've probably upgraded by now..."
- "This API has been around forever, version doesn't matter..."
- "I'll write it the modern way and they can adjust..."
- "The major version rarely changes how this works..."
- Naming a feature's behavior without knowing which major version the project pins

---

## Why It Works

1. **It exposes the recency bias.** The AI doesn't experience its knowledge as version-stamped — "how the library works" silently means "how the latest version works." Making the stamp explicit forces a comparison against the manifest.

2. **It distinguishes declared from resolved.** Pointing at the lockfile closes the semver-range loophole, where the manifest says `^4` and the AI assumes whichever 4.x it knows best.

3. **It legitimizes the old answer.** AIs upgrade-push because newer feels more helpful. Explicitly authorizing version-correct advice — with upgrades as a labeled aside — removes the incentive to answer for a version the project doesn't run.

4. **It makes breaking-change boundaries the checkpoints.** Most version damage clusters at a handful of known cliffs per library; asking "which side is this project on" is a cheap, targeted question.

## Origin

An engineer asked how to handle redirects in their web framework. The AI answered for the framework's current major version — a config-based approach introduced two majors after the version in the project's manifest. The engineer spent an afternoon debugging why the config was ignored before checking the docs for their actual version, where redirects were middleware. The manifest that would have prevented it all was 30 lines long and never opened.
