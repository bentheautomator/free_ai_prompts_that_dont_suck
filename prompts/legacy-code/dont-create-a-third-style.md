---
title: Don't Create a Third Style
slug: dont-create-a-third-style
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: medium
one_liner: "Prevents half-migrations that leave the codebase with three competing styles"
---

# Don't Create a Third Style

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "improving" a codebase mid-migration by introducing a third pattern that matches neither the old style nor the target style.

**[Copy-paste ready version](../../install/dont-create-a-third-style.md)** — just the instruction block, no explanation.

## The Problem

Most legacy codebases are mid-migration somewhere: the old promise chains are being converted to async/await, the class components to hooks, the raw SQL to the query builder. Two styles coexist, and everyone on the team knows which one is the past and which is the future. Then an AI assistant touches a file and writes the pattern it considers best practice — which is neither. Now there are three styles, and the next reader can no longer tell the migration's direction by reading code. Worse, the third style becomes precedent: future contributors (human and AI) pattern-match against it and propagate it.

A variant of the same failure happens within a single file: the assistant converts the four functions it touched to the new style and leaves six in the old one, with no record of why the file is split. File-by-file and function-by-function drive-by upgrades feel like progress, but a migration's value comes from convergence. Adding entropy to the middle of one is anti-progress wearing progress's clothes.

AI assistants do this because they optimize each edit locally — "what's the best way to write this function?" — while migration discipline is a global property they can't see without being told it exists.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Create a Third Style

NEVER introduce a new pattern into a codebase that already contains two versions of that pattern. A codebase mid-migration has an old style and a target style; your job is to detect both and write the target style, not your preferred style.

Before writing code in a legacy codebase:

- Survey how the codebase already does the thing you're about to do. If you find two patterns, that's a migration in progress — identify which is newer using `git log` on representative files, or check for a migration note in README, CONTRIBUTING, or ADR docs.
- Write new code in the target style exactly as the codebase practices it, even if you know a pattern you consider better. Your better pattern is a third style.
- Don't opportunistically convert old-style code you happen to be editing unless the user asked. If conversion is in scope, convert the whole unit the codebase migrates by (whole file, whole module), not just the lines you touched.
- If you genuinely cannot tell which style is the target, ask. One question beats guessing the direction of someone else's migration.
- If you believe both existing styles are wrong, say so in your summary as a suggestion. Do not act on it unilaterally.

The measure of consistency is not "is each function ideal" but "can a reader predict what the next file looks like."

**Red flags that you're about to violate this:**
- "Neither of their patterns is current best practice, so I'll use the right one."
- "I'll convert just these two functions since I'm editing them anyway."
- "Mixing styles is fine, it all works."
- "The new style everyone recommends now isn't either of these."
- "This file is already inconsistent, one more variant won't hurt."

---

## Why It Works

1. **It gives the AI a detection procedure, not just a value.** "Match the codebase" fails when the codebase has two styles; "find both, identify the newer, write that" resolves the exact ambiguity that produces style number three.
2. **It defines the migration unit.** Converting whole files instead of touched lines is what separates advancing a migration from scattering it.
3. **It redirects pattern knowledge into suggestions.** The AI's belief that it knows a better way gets a legitimate channel (the summary) instead of an illegitimate one (the diff).
4. **It frames consistency as predictability,** which is the property migrations actually protect — readers and tools that can assume convergence.

## Origin

A team eighteen months into moving data access from raw SQL to a repository pattern asked an assistant for a new lookup endpoint. The assistant delivered it using an ORM directly — cleaner than both existing approaches, and matching neither. It passed review on a busy Friday. Within a quarter, four more endpoints used the ORM style, copied from the first by people who reasonably assumed it was the new direction. The migration now had three endpoints' worth of a second target, and the eventual reconciliation consumed a sprint that the original migration plan had not budgeted.
