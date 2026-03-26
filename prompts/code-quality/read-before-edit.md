---
title: Read Before Edit
slug: read-before-edit
category: code-quality
tags: [universal, foundational, essential]
works_with: all
severity: critical
one_liner: "AI making blind edits based on assumptions instead of reading the file"
---

# Read Before Edit

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from making blind edits based on assumptions about file contents.

## The Problem

You tell the AI to change something in a file. Instead of reading the file first, it generates a plausible-looking edit based on what it *thinks* the file contains. The edit either doesn't match the actual code (causing a failed patch), or worse — it silently overwrites something important because the AI hallucinated the surrounding context.

This happens because AI models have strong priors about what code "probably looks like." Given a filename and a description of what to change, they can generate a convincing edit without ever looking at the real file. The edit applies cleanly about 60% of the time. The other 40% is wasted time, broken code, or subtle bugs from mismatched context.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read Before Edit

NEVER edit a file you haven't read in this session.

**Before modifying any file, you MUST:**
1. Read the file (or the relevant section of it)
2. Understand the existing patterns, naming conventions, and structure
3. Make changes that are consistent with what's already there

**Why:** AI assistants will generate edits based on assumptions about file contents rather than reading the actual code. This causes failed patches, overwrites working code, and introduces inconsistencies with existing patterns.

**This means:**
- Read the file before writing to it — every time, no exceptions
- If the file is large, read at least the section you're modifying plus surrounding context
- Follow the patterns you see, not the patterns you'd prefer
- Match existing naming conventions, indentation, and code style — even if they're not what you'd choose

**Red flags that you're about to violate this:**
- "Based on the typical structure of this type of file..."
- "This file probably contains..."
- "I'll add the standard boilerplate for..."
- Generating an edit without a preceding file read

---

## Why It Works

1. **Eliminates hallucinated context.** When forced to read first, the AI works with real code instead of guessed code. This alone eliminates most failed patches.

2. **Enforces pattern consistency.** AI assistants have strong opinions about code style. Left to their own devices, they'll introduce their preferred patterns into your codebase. Reading first forces them to match *your* patterns.

3. **Catches assumptions early.** The AI might assume a function signature, a variable name, or an import path. Reading the file first surfaces the real names and paths before any edits are attempted.

## Origin

A developer asked their AI assistant to "add error handling to the database module." The AI generated a well-structured try/catch wrapper — for a function that didn't exist. The file used a completely different pattern (Result types, not exceptions). The edit applied without errors but introduced a paradigm mismatch that took an hour to untangle. Reading the file first would have taken five seconds.
