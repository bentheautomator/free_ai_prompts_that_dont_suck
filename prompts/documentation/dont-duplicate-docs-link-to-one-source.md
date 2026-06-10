---
title: Don't Duplicate Docs, Link to One Source
slug: dont-duplicate-docs-link-to-one-source
category: documentation
tags: [universal, docs]
works_with: all
severity: medium
one_liner: "Copy-pasting the same docs into multiple files that then silently diverge"
---

# Don't Duplicate Docs, Link to One Source

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from copy-pasting the same documentation into multiple files, creating copies that drift apart until each one is differently wrong.

**[Copy-paste ready version](../../install/dont-duplicate-docs-link-to-one-source.md)** — just the instruction block, no explanation.

## The Problem

Asked to "add setup instructions to the new service's README," the AI helpfully copies the environment variable table from the root README, the auth setup from `docs/getting-started.md`, and the Docker steps from the wiki export. Now there are four copies of the setup instructions. Six weeks later someone changes the auth flow and updates one of them. The repo now contains three confident, detailed, mutually contradictory descriptions of how to set up auth, and a new hire will find the wrong one first, because wrong ones outnumber the right one.

AI assistants duplicate because copying is locally optimal: the new README is more complete, the user's immediate request is more thoroughly satisfied, and the divergence cost lands months later on someone else. The model has no memory of the maintenance burden because it will never do the maintenance. Every copy looks like added value at write time.

Duplicated docs don't just go stale; they go stale *independently*, which means readers can't even tell which copy is authoritative by checking dates.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Duplicate Docs, Link to One Source

NEVER copy documentation content from one file into another. Link to the existing source instead. Every copy you create is a future contradiction.

The problem: duplicated docs diverge silently the first time someone updates only one copy, and readers have no way to know which version is current.

Rules:
- Before writing docs for a topic, search for existing docs on it (README, docs/, CONTRIBUTING, wiki files). If they exist, link to them
- A link plus one orienting sentence ("See [Auth setup](../docs/auth.md); this service uses the standard flow with `SERVICE_NAME=billing`") beats a pasted section every time
- It is fine to duplicate a single command or one-line fact when a link would be disruptive; it is not fine to duplicate tables, procedures, or multi-step instructions
- If the existing doc is incomplete, improve it in place and link to it; do not write a better competing copy elsewhere
- If you find docs already duplicated, don't add a third copy and don't silently pick one. Flag the duplication to the user
- When content genuinely must appear in two places (e.g., generated output), make one the declared source and mark the other as generated or mirrored

**Red flags that you're about to violate this:**
- "The reader shouldn't have to click through to another file..."
- "I'll copy it now and they can consolidate later..."
- "This README should be self-contained..."
- "It's only a small table..."
- "The other doc is in a different folder, so this is a different audience..."
- "Copying is faster than restructuring the existing doc..."

---

## Why It Works

1. **It targets the divergence mechanism, not the copy itself.** Copies aren't wrong at creation; they become wrong at first single-sided update. Links structurally cannot diverge, because there is nothing to update twice.

2. **The search-first step catches duplication before it happens.** Most AI duplication occurs because the model never looked for existing coverage. A mandatory search converts "didn't know it existed" into "chose to link."

3. **It redirects improvement energy to the canonical copy.** "Improve in place and link" satisfies the model's urge to add value without spawning a competitor doc that splits future updates.

4. **It allows pragmatic exceptions with a bright line.** One command may be inlined; a procedure may not. Clear thresholds prevent the rule from being abandoned the first time a link feels awkward.

## Origin

A platform team found their deployment steps documented in five places: root README, two service READMEs, an onboarding doc, and a runbook. Four said to run migrations before deploy; the newest, written during an AI-assisted refactor, said after, which had been briefly true during a transition and then reverted in only the runbook. An engineer following the freshest-looking copy ran migrations against a live schema mid-deploy. The postmortem replaced four copies with links to one.
