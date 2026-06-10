---
title: No Wildcard Version Ranges
slug: no-wildcard-version-ranges
category: dependencies
tags: [universal, dependencies, versions]
works_with: all
severity: high
one_liner: "Stops declaring deps as *, latest, or >=x so installs stay reproducible"
---

# No Wildcard Version Ranges

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from declaring dependencies with unbounded ranges that resolve to something different every month.

**[Copy-paste ready version](../../install/no-wildcard-version-ranges.md)** — just the instruction block, no explanation.

## The Problem

When an AI assistant writes a manifest from scratch — a new requirements.txt, a generated package.json, a fresh pyproject.toml — it frequently declares versions as open-ended ranges or none at all: `requests` with no version, `"some-lib": "*"`, `">=2.0"`, or `"latest"`. The install works today, which is the only day the assistant can observe. A month later, a dependency ships a breaking 3.0, the unbounded range happily accepts it, and CI goes red on a project nobody has touched.

Unbounded ranges turn every upstream release into an unreviewed change to your project, scheduled by strangers. The failure is maximally confusing when it lands: the build that broke contains no diff, the developer who investigates wasn't around when the manifest was written, and "it worked yesterday" is literally true.

Assistants write unbounded versions because example code does. READMEs say `pip install requests`; tutorials show dependency lists without versions; the manifest the assistant generates mirrors that. Choosing an actual version constraint requires knowing the current release and deciding on an upgrade policy, both of which are extra steps with no immediate payoff — the unpinned install passes today either way.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Wildcard Version Ranges

NEVER declare a dependency with an unbounded version: no bare names in requirements.txt, no `*`, no `latest`, no open-ended `>=x` without an upper bound. Every dependency you add gets a bounded constraint anchored to the version you actually installed and tested.

- After installing, record what you got. JS: keep the caret range the package manager writes (`^4.2.1`) and ensure the lockfile is committed. Python without a lockfile-based tool: write `requests>=2.32,<3` or pin exact (`==2.32.3`) in requirements.txt — never a bare `requests`.
- Anchor to reality: the lower bound is the version you tested, not `0` and not a guess. Run `pip show <pkg>` / `npm ls <pkg>` to read the installed version instead of inventing one.
- The upper bound is the next major. Majors are documented breakage; an unbounded range pre-approves breakage sight unseen.
- If the project uses a lockfile tool (npm, pnpm, poetry, uv, cargo, bundler), the lockfile provides exactness — the manifest range can stay flexible, but it still must not be `*` or `latest`, because the manifest is what governs the next re-resolution.
- When generating a manifest for example code or a scaffold, pin there too. Scaffolds get copied into production verbatim.

**Red flags that you're about to violate this:**
- "I'll leave the version off so it always gets the newest."
- "latest keeps the project up to date automatically."
- "I don't know the current version, so an open range is safer."
- "This is just a quick script; versioning it is ceremony."
- "The README's install command doesn't specify a version either."

---

## Why It Works

1. **It reframes an open range as pre-approved future breakage**, countering the AI's framing of it as flexibility or freshness.
2. **It replaces guessing with reading.** "Run `pip show` and write down what's installed" eliminates the actual blocker — the AI often omits versions because it doesn't know the current one and won't admit it.
3. **It distinguishes lockfile-backed projects from raw manifests**, so the rule produces correct behavior in both worlds instead of cargo-cult exact-pinning where the lockfile already does that job.
4. **It covers scaffolds and examples explicitly**, which is where most unbounded manifests are born before being promoted to production unchanged.

## Origin

An assistant generated a requirements.txt for a data pipeline with nine bare package names, no versions. The pipeline ran nightly for five weeks, then an upstream library released a major that renamed its core entry point, and the 2 a.m. run died on an ImportError. The on-call engineer spent the first hour looking for a code change that didn't exist — the breaking commit was in someone else's repository, merged the previous afternoon.
