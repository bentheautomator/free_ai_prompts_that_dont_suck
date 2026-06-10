---
title: Match the Language Version Target
slug: match-the-language-version-target
category: code-quality
tags: [universal, compatibility]
works_with: all
severity: high
one_liner: "AI using syntax newer than the language version the project targets"
---

# Match the Language Version Target

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing syntax and features from a newer language version than the project builds against.

**[Copy-paste ready version](../../install/match-the-language-version-target.md)** — just the instruction block, no explanation.

## The Problem

Python's `match` statement in a service that deploys on 3.9. The walrus operator in a library claiming 3.7 support. `Array.prototype.at()` in a frontend whose browserslist still includes browsers that never heard of it. Java records in a codebase compiled with `--release 11`. AI models write in the newest comfortable dialect of every language because recent syntax is heavily represented in training data and is, frankly, nicer — but the project's runtime doesn't care what's nicer. It cares what `python_requires`, `tsconfig`'s `target`, `go.mod`'s directive, or the Dockerfile's base image says.

The failure profile depends on the stack, and the quiet end is the dangerous one. A `SyntaxError` on 3.9 at least fails fast. But transpiled frontend code can pass every build and test — run on modern Node, transpile syntax but not *APIs* — and then throw `TypeError: a.at is not a function` only in the older browsers in the support matrix, which are precisely the ones nobody on the team uses daily. Library authors get the cruelest version: the package installs fine everywhere and crashes only on the downstream user's older runtime, as a bug report from a stranger.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the Language Version Target

NEVER use language syntax or runtime features newer than what the project targets. The target version is a declared fact — find it before writing anything fancy, and write to it.

You default to the newest dialect you know. The project deploys on what it deploys on, and "nicer syntax" is not a feature on a runtime that throws `SyntaxError` at import time.

**Find the target first:**
- Python: `requires-python`/`python_requires` in `pyproject.toml`/`setup.py`, CI matrix, Dockerfile base image
- JS/TS: `tsconfig.json` `target` and `lib`, `browserslist`, `engines` in `package.json`, Babel config
- Go: the `go` directive in `go.mod` • Java: `--release`/`sourceCompatibility` • Ruby: `required_ruby_version` • C#: `LangVersion`/`TargetFramework`
- If several disagree, honor the oldest one that's actually deployed against

**Then respect it, including the subtle cases:**
- Syntax is only half the rule — built-in APIs and standard-library additions version too (`str.removeprefix` is 3.9+, `Array.at` is ES2022, `zoneinfo` is 3.9+). Transpilers convert syntax, not missing APIs, unless polyfills are configured
- Libraries with declared version support must be written to their *minimum* supported version, not the maintainer's laptop
- Check what the codebase itself uses: if no f-strings appear anywhere, there may be a reason — match the dialect you observe
- If a newer feature would genuinely improve the change, propose the version bump explicitly; don't smuggle it in as syntax

**Red flags that you're about to violate this:**
- "Modern Python/JS handles this elegantly with..."
- "Everyone's on at least version X by now..."
- "The transpiler will take care of it..." (of the API too?)
- "This syntax has been around for a couple of years..."
- "Tests pass locally, so compatibility is fine..." (local runtime ≠ target runtime)
- Using a feature without knowing which version introduced it and which version this project targets

---

## Why It Works

1. **It converts taste into lookup.** "Write compatible code" is vague; "find the declared target in these specific files, then write to it" is a two-minute procedure with a definite answer. The AI follows procedures far more reliably than vibes.

2. **It splits syntax from APIs.** The transpiler rationalization is half-true — and the false half (missing runtime APIs) is where modern frontend breakage actually lives. Making the distinction explicit defuses the AI's most convincing excuse.

3. **It flags the test-pass illusion.** Local tests run on the dev runtime, not the oldest supported one. Naming that gap stops green tests from laundering incompatible code.

4. **It legitimizes wanting the new feature.** The pull toward modern syntax is real and sometimes right. Routing it through an explicit version-bump proposal lets the AI advocate instead of smuggle.

## Origin

A utility library declaring Python 3.8 support gained an AI-written helper using `functools.cache` — added in 3.9. CI ran only on 3.11, so everything stayed green through release. The first issue arrived within a day from a downstream user on 3.8: `ImportError` at package import time, meaning the entire library was unusable, not just the new helper. The patch release, the apology issue thread, and the addition of a 3.8 CI job all traced back to one decorator chosen for elegance.
