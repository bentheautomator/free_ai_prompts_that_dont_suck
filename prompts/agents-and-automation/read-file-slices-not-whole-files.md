---
title: Read File Slices, Not Whole Files
slug: read-file-slices-not-whole-files
category: agents-and-automation
tags: [universal, agents, context]
works_with: all
severity: high
one_liner: "Dumping a 12,000-line file into context and drowning the session in it"
---

# Read File Slices, Not Whole Files

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the agent from loading enormous files wholesale into its context window when it needs thirty lines of them.

**[Copy-paste ready version](../../install/read-file-slices-not-whole-files.md)** — just the instruction block, no explanation.

## The Problem

The agent needs to check one function in `schema.sql`, so it reads `schema.sql` — all 14,000 lines of it. Then a generated API client, 8,000 lines, to confirm one method signature. Then a lockfile, because why not. Two reads into the task, half the context window is occupied by content the agent will never reference again, and everything that matters — the user's instructions, the plan, the actual edits — is now competing for what's left.

Agents default to whole-file reads because reading more feels safer than reading less, and because the cost is invisible at the moment of the read. The bill arrives later and is paid in degraded behavior: earlier instructions slip, the plan gets fuzzy, and the session hits compaction or the context ceiling mid-task. A long session's most precious resource is context, and giant file dumps are the fastest way to torch it.

The irony is that the giant files least worth reading are the ones agents most often dump: lockfiles, generated code, vendored bundles, data fixtures, minified assets. Files written by machines, for machines, swallowed whole by a model that needed one line.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read File Slices, Not Whole Files

NEVER read an entire large file into context when you need part of it. Search first, then read the matching region. Your context window is the session's scarcest resource, and a single whole-file dump of a big file can cripple everything that comes after it.

The core problem: reading everything feels thorough, but the cost lands later — as forgotten instructions, lost plans, and premature compaction.

- Before reading any file, check its size (line count or bytes). Over roughly 500 lines: do not read it whole. Use search (grep or equivalent) to locate what you need, then read just that range with offset and limit.
- Reading a definition? Search for the symbol, read 50 lines around the hit. Need broader structure? Read the imports and the outline (function and class signatures), not every body.
- NEVER dump machine-generated files: lockfiles, generated clients, minified bundles, snapshots, large fixtures, vendored dependencies. Query them surgically or not at all.
- For logs and data files, read the head and the tail, or grep for the error you're hunting. The middle 40,000 lines are not for you.
- If you genuinely need to process a whole huge file, that's a job for a tool, not your context: write a script, or filter it through grep, awk, or jq, and read only the result.
- If you catch yourself having just dumped a huge file, don't compound it by dumping the next one. Note what you actually needed and switch to targeted reads.

**Red flags that you're about to violate this:**
- "Let me read the whole file to get full context..."
- "It's easier to just load it all in..."
- "I should understand the entire schema before changing this column..."
- "I'll read the lockfile to see what versions are installed..."
- "Better to have it all available just in case..."

---

## Why It Works

1. **It prices the read.** Agents dump files because the cost is invisible at decision time. Stating that the bill is paid in forgotten instructions and lost plans moves the cost to where the decision happens.

2. **It gives a concrete threshold.** "Don't read large files" invites judgment calls that always resolve toward reading; "over ~500 lines, slice it" resolves them mechanically.

3. **It names the worst offenders.** Lockfiles, generated code, and fixtures account for the most egregious dumps, and they're identifiable by name — so the rule blocklists them outright instead of relying on size intuition.

4. **It supplies the substitute behavior.** "Search, then read the region" is a complete replacement workflow, so compliance never requires sacrificing the information — only the bulk.

## Origin

Asked to add one column to one table, an agent began by reading the project's entire generated Prisma client and a 16,000-line SQL dump "for context." Both reads succeeded; the session did not. By the time it came to write the migration, the user's constraints from the opening message had been compacted away, and the agent wrote the migration against the wrong database dialect — a fact stated plainly in the instructions it had crowded out.
