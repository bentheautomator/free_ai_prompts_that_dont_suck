---
title: Don't Write Aspirational READMEs
slug: dont-write-aspirational-readmes
category: documentation
tags: [universal, docs, readme]
works_with: all
severity: medium
one_liner: "READMEs documenting planned features as if they already shipped"
---

# Don't Write Aspirational READMEs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents READMEs that describe the project you wish existed instead of the one in the repo.

**[Copy-paste ready version](../../install/dont-write-aspirational-readmes.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "write a README" for a half-built project and you get marketing copy: "Supports PostgreSQL, MySQL, and SQLite," when only the Postgres adapter exists. "Fully configurable retry policies," meaning there's a `retries` field that one code path reads. The model fills the feature list from the project's apparent *intent* — the interfaces, the TODOs, the roadmap issue — rather than its actual state.

The result is a README that reads like a press release for version 3.0 of a project sitting at version 0.2. New contributors burn an afternoon trying to configure the MySQL adapter before discovering it's an empty interface. Users file bugs for features that were never built. And because the README is the most-read file in the repo, the lie compounds with every reader.

AI assistants do this because polished READMEs in their training data describe finished products, and because describing intent requires no verification while describing reality does. The aspirational README is the path of least resistance: it sounds complete, it flatters the project, and nothing in the model's feedback loop punishes the gap between prose and code.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Write Aspirational READMEs

NEVER describe a feature in a README as existing unless you have verified it exists in the code. A README documents the repo as it is, not the roadmap.

The core problem: READMEs written from intent describe features that don't exist, and readers act on them — installing, configuring, and filing bugs against vapor.

Rules:
- Before listing a feature, find the code that implements it. An interface, a stub, or a TODO is not a feature
- Before documenting a config option, find where it's read. A field in a config struct that nothing consumes does not count
- Planned work goes in a clearly labeled Roadmap or Status section, in future tense: "Planned: MySQL adapter" — never in the feature list
- If something is partially implemented, say which part works: "CSV export (JSON export not yet implemented)"
- Don't inherit claims from package descriptions, issue titles, or old README text without re-verifying them against current code
- When you can't verify a claim, either verify it or omit it — don't soften it with "should" and ship it anyway

**Red flags that you're about to violate this:**
- "The interface is there, so the feature basically exists..."
- "The roadmap says this is coming, so I'll include it..."
- "A fuller feature list makes the project look more credible..."
- "The old README claimed this, so it's probably true..."
- "I'll describe what the project is meant to do..."
- "Surely they'll finish this part soon..."

---

## Why It Works

1. **It changes the source of truth from intent to code.** The model's default README input is the project's apparent purpose. Requiring a code-level verification step for each claim makes "find the implementation" the gating action, and unimplemented features fail the gate.

2. **It gives aspiration a legal home.** Banning future features outright would just get them smuggled into the feature list. A labeled Roadmap section gives the model somewhere compliant to put them, which removes the pressure to misfile them.

3. **It targets partial implementation, the hardest case.** Fully fake features are rare; half-built ones are constant. The "say which part works" rule converts a binary claim into an honest fraction.

## Origin

A data pipeline project's README, written by an assistant from the repo's interfaces, listed "S3, GCS, and Azure Blob storage backends." Only S3 was implemented; the other two were empty adapter classes generated for symmetry. A downstream team chose the library specifically for GCS support, built two weeks of integration work around it, and discovered the adapter threw `NotImplementedError` only when they ran against a real bucket. The fix in the README took one line. The trust took longer.
