---
title: Match the File's Existing Indentation
slug: match-existing-indentation
category: file-handling
tags: [universal, files, style]
works_with: all
severity: medium
one_liner: "Stops edits from mixing tabs and spaces against a file's established style"
---

# Match the File's Existing Indentation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents new lines from being indented with the wrong character or width for the file, creating mixed-indentation messes and outright syntax errors.

**[Copy-paste ready version](../../install/match-existing-indentation.md)** — just the instruction block, no explanation.

## The Problem

The assistant's default is spaces, usually four or two. The file's reality might be tabs (Go, plenty of legacy code, every Makefile), three-space C from 2009, or two-space YAML nested five levels deep. New lines written in the assistant's preferred style instead of the file's produce mixed indentation that renders fine at one tab-width and like a ransom note at another — and in several formats it's not cosmetic. Python 3 raises `TabError` on inconsistent tab/space mixing within a block. YAML forbids tabs in indentation entirely; one tab character makes the document unparseable. Makefile semantics are inverted: recipe lines *require* a leading tab, and eight spaces that look identical produce `*** missing separator. Stop.`

The diff damage compounds the syntax damage. Re-indenting surrounding lines "for consistency" turns a small edit into a churn diff; linters with `no-mixed-spaces-and-tabs` or an `.editorconfig` check fail CI on the new lines. Indentation characters are invisible in most rendered views — which is exactly why an assistant must determine them by evidence, not by habit.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the File's Existing Indentation

ALWAYS indent new and edited lines with exactly the file's existing indentation character and width. Your preference is irrelevant; the file has already decided.

Tabs and spaces are invisible in rendered views but distinct to parsers: Python raises TabError on mixes, YAML rejects tabs outright, and Makefiles require literal tabs where spaces fatally substitute.

- Determine the style by evidence before writing: `cat -A file | head` (tabs show as `^I`) or check what character existing lines start with. Read the `.editorconfig` if present — but the file's actual content wins over the config when they disagree, because matching the file is what keeps the diff clean.
- Match the width too: two-space JS stays two-space; the 3-space legacy file gets 3-space additions. Consistency within the file beats correctness against any external standard.
- Format-fixed cases, no judgment required: Makefile recipe lines take a literal tab; YAML indentation never contains tabs; Go files are tabs (`gofmt` says so).
- Never re-indent lines you weren't asked to change. A correct edit indented in the file's own style touches only your lines; "fixing" the file's style is churn that buries the edit (and a separate task if anyone wants it).
- Continuation alignments matter as well: if the file aligns wrapped arguments under the opening paren, do that, even if you'd prefer a hanging indent.
- Mixed-style files (tabs above, spaces below) get matched locally: indent like the lines immediately around your edit.

**Red flags that you're about to violate this:**

- "Four spaces is standard; the file should agree."
- "Tabs and spaces look the same here, so it doesn't matter."
- "I'll convert the file to spaces while I'm editing it."
- "The Makefile recipe can use spaces; it's all whitespace."
- "My block is internally consistent, that's enough." (Python compares your block against its neighbors.)

---

## Why It Works

1. **It lists the formats where this is a parser error, not a style nit** — TabError, YAML's tab ban, Makefile's missing-separator — so the rule carries build-breaking stakes, which is what actually changes behavior.
2. **"Determine by evidence" beats "be consistent" because the property is invisible:** `cat -A` makes tabs visible in one command, converting a guess into a fact before the first wrong character lands.
3. **The local-matching rule for mixed files prevents the overcorrection spiral**, where an assistant notices inconsistency and "helpfully" normalizes 800 lines, producing the churn diff this category exists to prevent.

## Origin

A two-line addition to a deployment Makefile arrived indented with spaces — visually identical to the tab-indented recipe lines above it in every diff view the reviewer used. CI didn't run the target; the first person to run `make deploy` got `*** missing separator. Stop.` and spent twenty minutes staring at a recipe that looked exactly like its working neighbors, until `cat -A` showed `^I` on every line but two.
