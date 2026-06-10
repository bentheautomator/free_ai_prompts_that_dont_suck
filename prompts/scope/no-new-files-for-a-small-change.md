---
title: No New Files for a Small Change
slug: no-new-files-for-a-small-change
category: scope
tags: [universal, scope]
works_with: all
severity: medium
one_liner: "AI splitting a small change across new modules nobody asked for"
---

# No New Files for a Small Change

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from answering a small request with a spread of new files, modules, and barrel exports.

**[Copy-paste ready version](../../install/no-new-files-for-a-small-change.md)** — just the instruction block, no explanation.

## The Problem

"Add validation to the signup form" should land in the form's file. Instead, the project gains `validators.ts`, `validation-types.ts`, `validation-constants.ts`, and an `index.ts` to re-export them, with the actual form change importing from all four. One small behavior, four new files, and a directory listing that now lies about the size of the feature.

Assistants do this because file-per-concern reads as organization, and organization reads as quality. But every new file is a permanent navigation cost: another place to look, another import path to learn, another file that shows up in searches forever. Code that changes together should live together, and a validation rule used by one form changes with that form. Splitting it four ways optimizes for an imagined future codebase at the expense of every present reader.

There's also a review asymmetry: new files get less scrutiny than modified ones, because diffs of new files have no "before" to compare against. Scattering logic into fresh files is, accidentally, a way of making it harder to review.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No New Files for a Small Change

Put changes in existing files. NEVER create new files or modules for a change unless the request names them or the addition genuinely cannot live where related code already lives.

The core problem: each new file is permanent navigation and review surface, and splitting a small feature across several of them hides its actual size and separates code that changes together.

- Default location for new logic: the file containing the code that uses it
- Do not create types files, constants files, helpers files, or barrel/index re-export files as part of a feature change
- Do not split one cohesive change across multiple new files to satisfy a one-concern-per-file aesthetic the request didn't ask for
- Creating a file is justified when the request asks for one, when the project's strong existing convention dictates it (e.g., one file per route or migration), or when the new code has no reasonable existing home
- When a convention does dictate a new file, create the minimum: one file, no accompanying index, types, or constants satellites
- If you think a change is large enough to deserve its own module, say so in one sentence and let the user choose before you scatter it

**Red flags that you're about to violate this:**
- "I'll put these types in their own file to keep things organized..."
- "Constants belong in a constants file..."
- "This file is getting long, I'll split things out while I'm here..."
- "A barrel export makes the imports cleaner..."
- "Separating concerns into modules is better architecture..."
- "Future features will want this in its own file anyway..."

---

## Why It Works

1. **It sets the default location explicitly.** "The file containing the code that uses it" answers the placement question before the AI's organization instinct does, removing the decision point where creep happens.

2. **It names the satellite pattern.** Types/constants/index files are the specific reflex; banning them by name works where a general "minimize files" would be argued around.

3. **It surfaces the review asymmetry.** New files dodge before/after comparison; stating this reframes file creation as scrutiny avoidance, which the AI does not want to be doing.

4. **It defers the module decision to the user.** Sometimes a new module is right; making it a one-sentence proposal keeps the judgment available without letting the AI exercise it unilaterally.

## Origin

A request to add two computed fields to an API response produced seven new files: a serializer module, a types module, two constants files, a helpers file, and two index files re-exporting the rest. The actual logic totaled 30 lines. A year later, a security review of that endpoint took twice the estimated time because the reviewer had to reassemble the 30 lines from seven locations, and one of the constants files had meanwhile attracted unrelated constants from three other features.
