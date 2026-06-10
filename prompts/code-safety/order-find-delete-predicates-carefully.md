---
title: Order Find Delete Predicates Carefully
slug: order-find-delete-predicates-carefully
category: code-safety
tags: [universal, shell, files]
works_with: all
severity: critical
one_liner: "AI misordering find -delete or flipping -mtime signs and deleting everything"
---

# Order Find Delete Predicates Carefully

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the two classic `find` deletion accidents: predicate order that deletes everything, and age tests that select the wrong side of the cutoff.

**[Copy-paste ready version](../../install/order-find-delete-predicates-carefully.md)** — just the instruction block, no explanation.

## The Problem

`find . -delete -name '*.tmp'` deletes everything under the current directory. Not the `.tmp` files — everything. `find` evaluates its expression left to right, and `-delete` placed before `-name` fires on every file *before* the name test is ever consulted. The correct command differs only in word order: `find . -name '*.tmp' -delete`. AI assistants generate both orderings, because in natural language "delete the tmp files" and "find files, tmp ones, delete" feel equivalent. To `find`, one of them is a tree-wide purge.

The second trap is age logic. `-mtime +7` means *older* than 7 days (actually 8+, thanks to rounding); `-mtime -7` means *newer*. A retention script meant to delete logs older than a week, written with the sign flipped, deletes the last week of logs and retains the ancient ones — the exact inverse, executed flawlessly. Add the quieter footguns (`-delete` implying `-depth`, missing `-type f` so directories qualify, unanchored start paths) and `find` deletion one-liners are among the most error-dense destructive commands an AI produces. They look declarative. They're a program, with evaluation order, and the bugs delete things.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Order Find Delete Predicates Carefully

A `find` expression is a program evaluated left to right, and `-delete` is an action that fires the moment it's reached. NEVER place `-delete` (or `-exec rm`) anywhere but last, and never run a deleting `find` whose selection you haven't already seen.

The core problem: `find . -delete -name '*.tmp'` deletes *everything* — the action runs before the filter is consulted. And `-mtime +7` vs `-mtime -7` (older vs. newer than 7 days) inverts a retention script into deleting exactly the files it was meant to keep.

- ALWAYS run the expression without the action first: `find . -name '*.tmp' -mtime +7 -type f` alone, read the listed files, *then* append `-delete` to the identical expression. The list is the contract; the delete must match it.
- `-delete` and `-exec rm` go last in the expression. If `-delete` appears before any test, the command is wrong — full stop.
- Get the age sign right by stating it in words: "+7 selects files modified MORE than 7 days ago." If deleting old files, you want `+`. Sanity-check by looking at the dry-run output's actual timestamps (`-printf '%T@ %p\n'` or pipe to `ls -la` via `-exec`).
- Constrain the match: `-type f` unless directories are truly intended; an explicit start path (never bare `.` in an unverified cwd); `-maxdepth` when recursion isn't needed.
- Mind the implicit OR trap: `-name '*.log' -o -name '*.tmp' -delete` applies `-delete` only to the second branch and not how you think — parenthesize: `\( -name '*.log' -o -name '*.tmp' \) -delete`.
- Count the dry-run results. A retention pass expecting dozens that matches thousands has a flipped sign or a broken test.

**Red flags that you're about to violate this:**
- "find with -delete in one shot, it's a standard cleanup idiom..."
- "Pretty sure +7 means within the last week..."
- "The predicate order is just stylistic..."
- "No need to preview, the name pattern is unambiguous..."
- "I'll add -o for the second extension and keep the same -delete..."

---

## Why It Works

1. **It reframes `find` as a program, not a query.** The AI treats the flags as an unordered set of filters; "evaluated left to right, action fires when reached" installs the execution model from which the predicate-order rule follows necessarily.

2. **It makes the dry run the contract.** "Run without the action, then append the action to the *identical* expression" leaves no gap between what was reviewed and what executes — the most common audit hole in destructive one-liners.

3. **It forces the age sign into words.** Sign confusion survives review because `+7` and `-7` both look plausible; requiring the English sentence ("more than 7 days ago") plus timestamp inspection catches the inversion before it deletes the new files.

## Origin

A log-retention one-liner produced by an assistant used `-mtime -30` to "delete logs older than 30 days." It deleted every log written in the last 30 days and preserved the archive of stale ones. The deletion ran from cron for four days before an incident responder went looking for yesterday's logs and found March. The fix was one character; the missing evidence stayed missing.
