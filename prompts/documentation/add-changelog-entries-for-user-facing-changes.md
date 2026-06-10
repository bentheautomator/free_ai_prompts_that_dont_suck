---
title: Add Changelog Entries for User-Facing Changes
slug: add-changelog-entries-for-user-facing-changes
category: documentation
tags: [universal, docs, changelog]
works_with: all
severity: medium
one_liner: "User-facing changes shipping with no changelog entry at all"
---

# Add Changelog Entries for User-Facing Changes

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents user-facing changes from shipping without any changelog entry, leaving releases that look like nothing happened.

**[Copy-paste ready version](../../install/add-changelog-entries-for-user-facing-changes.md)** — just the instruction block, no explanation.

## The Problem

The repo has a `CHANGELOG.md`. It has an `## Unreleased` section. The AI just changed a default, fixed a user-reported bug, and added a CLI flag. The changelog got zero new lines. Next release, whoever cuts the version stares at an empty Unreleased section, shrugs, writes "miscellaneous fixes," and every downstream user upgrades blind.

AI assistants skip the changelog because nothing asks for it. The task said "fix the pagination bug," and the changelog is in a file the AI never opened, with no test asserting its freshness. Unlike code, a missing changelog entry has no failure signal until weeks later when someone diffs two versions trying to figure out what broke their integration. The information needed to write the entry — what changed, why, who it affects — peaks at the moment of the change and decays to zero by release time.

The result is a changelog that technically exists but functionally lies: it implies releases contained only what's listed. That's worse than having no changelog, because users trust it as the canonical record.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Add Changelog Entries for User-Facing Changes

ALWAYS add a changelog entry when your change affects users, if the repo maintains a changelog. The entry is part of the change, not an optional garnish.

The problem: changelog gaps are invisible at commit time and unrecoverable at release time, when nobody remembers what shipped.

Rules:
- Before finishing, check whether the repo has `CHANGELOG.md`, `CHANGES.rst`, a `changelog.d/` fragments directory, or a documented changelog convention
- A change is user-facing if it alters behavior, output, defaults, flags, config, public APIs, error messages, or performance someone would notice. Internal refactors with identical behavior are not
- Add the entry to the Unreleased (or current dev) section, following the file's existing format exactly: same heading levels, same categories (Added/Changed/Fixed), same entry style
- If the repo uses changelog fragments (towncrier, changesets), create the fragment file instead of editing the main changelog
- One entry per logical change, written for the user who upgrades, not the developer who committed
- If you genuinely cannot tell whether the project wants an entry, say so explicitly instead of silently skipping it
- Do not invent a changelog file in a repo that has none; that is a maintainer decision

**Red flags that you're about to violate this:**
- "It's a small fix, not changelog-worthy..."
- "The commit message already explains it..."
- "Someone will batch-update the changelog at release time..."
- "The user didn't ask me to touch the changelog..."
- "I'm not sure which section it goes in, so I'll skip it..."
- "The changelog looks neglected anyway..."

---

## Why It Works

1. **It moves the entry to peak-knowledge time.** The author of a change can describe it in one accurate line; the release manager three weeks later can only guess from commit titles.

2. **It defines "user-facing" mechanically.** The vague instinct "is this changelog-worthy?" defaults to no. A concrete list — behavior, defaults, flags, APIs, errors — converts the judgment call into a checklist.

3. **It respects the repo's existing machinery.** Pointing at fragments directories and format-matching prevents the failure mode where the AI helps by writing an entry in the wrong place or wrong shape, which maintainers then have to undo.

4. **It permits silence only when explicit.** "No entry needed because the change is internal" is reviewable. Skipping wordlessly is not.

## Origin

A library bumped a minor version with an empty changelog section after a quarter of AI-assisted maintenance. One of the unlisted changes had tightened input validation, and a downstream team's pipeline started rejecting records on upgrade. They spent a day bisecting versions to find a change that one sentence in the changelog would have surfaced in ten seconds. The fix was known; the record of it was the thing missing.
