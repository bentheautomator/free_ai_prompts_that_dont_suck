---
title: Remove Orphaned Imports
slug: remove-orphaned-imports
category: code-quality
tags: [universal, imports]
works_with: all
severity: medium
one_liner: "AI removing code but leaving its now-unused imports rotting at the top"
---

# Remove Orphaned Imports

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from leaving dead imports behind when it removes or rewrites the code that used them.

**[Copy-paste ready version](../../install/remove-orphaned-imports.md)** — just the instruction block, no explanation.

## The Problem

An AI rewrites your data-fetching logic from `axios` to the native `fetch`, does a perfectly good job of it, and leaves `import axios from 'axios'` sitting at the top of the file like a coat someone forgot at a party. It happens because edits are local: the model's attention is on the function it's changing, and the import block — fifty lines up, written in a different edit, by a different "thought" — never re-enters consideration.

In strict-lint projects, this is immediate CI failure on `no-unused-vars`, which means a whole extra round trip for a one-line fix. In looser projects it's quieter and worse: dead imports accumulate, every future reader wastes time figuring out whether `lodash` is actually used in this file, dependency-analysis tools report false positives, and someone eventually keeps a package in `package.json` purely because twelve files still import it for no reason. In languages like Python, an orphaned import can even keep real side effects alive — modules that register things at import time keep registering them, invisibly.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Remove Orphaned Imports

ALWAYS reconcile the import block after editing a file. When you remove or rewrite code, the imports that only served that code must leave with it.

Your edits are local; imports are global to the file. Code you delete in line 200 silently orphans a name declared in line 3, and you will not notice unless you look.

**After any edit that removes or replaces code:**
- Re-check every import in the file: is each imported name still referenced below? Remove the ones that aren't
- Removing one name from a multi-name import? Trim just that name (`import { a, b }` → `import { a }`), don't delete bindings that are still used
- Apply the same reconciliation to the mirror case: code you *add* needs its imports added — never reference a name the file doesn't import just because the snippet in your head had it in scope
- Watch for imports kept alive only by side effects (Python module registration, CSS imports, polyfills) — if one looks unused but might be load-bearing, leave it and say so rather than guessing
- If the project has a lint rule or formatter that manages imports, run it on the touched files before declaring the edit complete

**Red flags that you're about to violate this:**
- "The edit is done — the function works now..." (without re-reading the imports)
- "The linter will clean those up eventually..."
- "I only touched the middle of the file, the top is unchanged..." (unchanged is the problem)
- "That import might be used somewhere else in the file, probably..."
- "Removing imports is risky, safer to leave them..."
- Declaring an edit finished without having looked at the import block since your change

---

## Why It Works

1. **It names the locality blind spot.** The model genuinely doesn't "see" line 3 while editing line 200. Making import reconciliation an explicit post-edit step compensates for an attention pattern the AI can't fix on its own.

2. **It pairs both failure directions.** Orphaned imports and missing imports are the same reconciliation skipped in opposite directions; handling them in one rule means one habit covers both.

3. **It handles the side-effect exception honestly.** "Some imports are load-bearing with zero references" is the one true reason to hesitate; giving it an explicit escape (leave it and say so) prevents the AI from using it as a blanket excuse.

4. **It delegates to tooling when tooling exists.** A formatter that organizes imports is a zero-judgment fix; the instruction makes running it part of "done" instead of an optional nicety.

## Origin

A migration off a deprecated HTTP client went smoothly — except the AI left the old client imported in nineteen files. The package couldn't be removed from the dependency tree because, as far as any tool could tell, it was used everywhere. It shipped in the production bundle for another five months, including through a security advisory against it that triggered a panicked audit. The audit's finding: every single import was dead.
