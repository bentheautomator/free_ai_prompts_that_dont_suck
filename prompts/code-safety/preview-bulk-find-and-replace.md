---
title: Preview Bulk Find-and-Replace Before Running It
slug: preview-bulk-find-and-replace
category: code-safety
tags: [universal, files, automation]
works_with: all
severity: high
one_liner: "AI running repo-wide sed or replace-all without checking what it matches"
---

# Preview Bulk Find-and-Replace Before Running It

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from firing a repo-wide search-and-replace that matches far more than it intended.

**[Copy-paste ready version](../../install/preview-bulk-find-and-replace.md)** — just the instruction block, no explanation.

## The Problem

You ask the AI to rename a function from `getData` to `fetchData`. It reaches for `sed -i 's/getData/fetchData/g'` across the whole repo and presses go. The pattern also matches `getDatabase`, `widgetData`, a string constant in a test fixture, a key in a JSON config that an external service depends on, and a line in the changelog. Now you have a build that fails in four places and one breakage that won't surface until production calls the renamed config key.

AI assistants do this because the replace looks atomic from the inside: one pattern, one command, done. The model never sees the match list, so it never confronts the false positives. A human running the same operation would instinctively grep first, eyeball the hits, and notice `getDatabase` in the output. The AI skips that step because nothing forces it to look.

The damage is rarely catastrophic on its own, but it's diffuse — dozens of files touched, a fraction of them wrongly, mixed in with legitimate changes. Untangling which edits were intended is slower than doing the rename by hand would have been.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preview Bulk Find-and-Replace Before Running It

NEVER run a multi-file search-and-replace without first listing every match and reviewing it. The pattern you wrote matches more than the thing you meant.

The core problem: a bulk replace is dozens of edits executed blind. False positives (substrings, strings in fixtures, config keys, docs) get rewritten alongside the real targets, and the wreckage is smeared across the whole tree.

- ALWAYS run the search alone first (`grep -rn 'pattern'`, ripgrep, or the editor's find-all) and read the full match list before any replacement.
- Anchor patterns hard: word boundaries (`\bgetData\b`), not bare substrings. `getData` must not match `getDatabase`.
- Report match counts per file. If the count surprises you — 200 hits when you expected 12 — stop and investigate before replacing.
- Exclude generated files, lockfiles, vendored code, and fixtures from the replace unless they are explicitly in scope.
- For mixed-context identifiers (the same word used as a function, a string, and a config key), do the edits file by file instead of one global pass.
- After the replace, re-run the original search. Zero remaining hits or a stated reason for each survivor.

**Red flags that you're about to violate this:**
- "A quick sed across the repo will handle this..."
- "The name is unique enough, nothing else will match..."
- "I'll just replace all and fix any stragglers after..."
- "Checking every match would take too long — there can't be many..."
- "The tests will catch it if I hit something wrong..."

---

## Why It Works

1. **It forces the AI to see the match list.** The failure happens because the model executes the replace without observing what it hits. Making the grep a mandatory prior step puts the false positives in front of it before they become edits.

2. **It makes surprise a stop condition.** "If the count surprises you, stop" converts a vague unease into an explicit halt rule at exactly the moment over-matching reveals itself.

3. **It names the lazy-pattern shortcut.** Requiring word boundaries closes the most common loophole — bare substring patterns that the AI writes because they're shorter.

## Origin

A developer asked an assistant to rename an internal `status` field to `state`. The assistant ran a global replace that also rewrote `status` inside an OpenAPI spec, a webhook payload builder, and seventeen test fixtures. CI went green because the fixtures and the code changed together. The external consumer of the webhook did not change with them, and the integration broke silently for two days.
