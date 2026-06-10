---
title: Never Overwrite Existing Files With Write
slug: never-overwrite-existing-files-with-write
category: code-safety
tags: [universal, files]
works_with: all
severity: critical
one_liner: "AI replacing a whole file with a partial rewrite, destroying everything else"
---

# Never Overwrite Existing Files With Write

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from replacing an entire existing file with a from-scratch rewrite that only contains the parts it remembered.

**[Copy-paste ready version](../../install/never-overwrite-existing-files-with-write.md)** — just the instruction block, no explanation.

## The Problem

You ask for a small change to `config/routes.py` — add one endpoint. The AI decides editing is fiddly, so it writes the whole file fresh. Except it only read the first 200 lines, or read it forty turns ago, or never read it at all. The new file contains the one endpoint you asked for plus whatever fraction of the original the AI had in context. The other 300 lines — middleware registration, a dozen routes someone else added last week — are gone. No diff, no warning, just a smaller file.

AI assistants do this because whole-file writes are easier than surgical edits: no anchor text to match, no risk of a failed edit operation. The model treats "write the file" and "edit the file" as interchangeable ways to reach the same end state. They are not. An edit can only damage what it touches. An overwrite silently deletes everything the AI didn't know about.

The worst cases are files that were modified outside the session — by the user, a formatter, or another tool — after the AI last read them. The AI confidently writes back its stale copy and erases the newer work.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Overwrite Existing Files With Write

NEVER replace an existing file with a full-file write when a targeted edit will do. A whole-file write deletes everything you did not include — including content you never read or no longer remember accurately.

The core problem: full rewrites feel equivalent to edits, but an edit can only damage the lines it touches, while an overwrite silently destroys every line missing from your version.

- ALWAYS use targeted edit operations (string replacement, patch, diff-based edits) to modify existing files.
- Before any full-file write to an existing path, read the complete current file in this same step — not from memory of an earlier read.
- If a file is too large to read fully, that is a reason to edit, never a reason to rewrite.
- Full-file writes are acceptable only for: brand-new files, files you created in this session, or when the user explicitly asks for a complete rewrite — and even then, read the current version first.
- If an edit operation fails because your anchor text doesn't match, re-read the file and fix the anchor. Do not fall back to "I'll just write the whole thing."
- After writing any existing file, state what the file previously contained that your version intentionally drops. If the answer is "I'm not sure," you have already failed.

**Red flags that you're about to violate this:**
- "It'll be cleaner to just rewrite the whole file..."
- "My edit keeps failing to match, so I'll write it from scratch..."
- "I remember what this file looks like from earlier..."
- "The file is mostly my code anyway..."
- "I'll reconstruct the parts I didn't read — they were probably boilerplate..."

---

## Why It Works

1. **It names the false equivalence.** The AI genuinely models "write" and "edit" as two routes to the same outcome. Stating that overwrites delete unknown content reframes the choice as destructive vs. non-destructive, not convenient vs. fiddly.

2. **It closes the failed-edit loophole.** Most overwrite disasters start as edit operations that couldn't find their anchor. Prescribing "re-read and retry" at exactly that moment intercepts the fallback.

3. **It forces a stale-context check.** Requiring a fresh read in the same step kills the "I read it earlier" rationalization, which is where most lost work actually comes from.

## Origin

A developer asked for one new field in a 600-line API schema file. The assistant's edit failed twice on whitespace mismatches, so it "helpfully" rewrote the file from its memory of a read done an hour earlier — before the developer had hand-added two new resource definitions. The rewrite shipped to a branch, passed CI because the deleted resources had no tests yet, and cost an afternoon of forensic diffing to reconstruct.
