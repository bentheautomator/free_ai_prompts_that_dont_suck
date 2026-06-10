---
title: Don't Clobber Files with Shell Redirection
slug: dont-clobber-with-redirection
category: file-handling
tags: [universal, files, shell]
works_with: all
severity: high
one_liner: "Stops a stray > from truncating a file you were still composing or reading"
---

# Don't Clobber Files with Shell Redirection

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents shell redirection mistakes — truncating `>` where `>>` was meant, redirecting a pipeline onto its own input — from destroying file contents mid-composition.

**[Copy-paste ready version](../../install/dont-clobber-with-redirection.md)** — just the instruction block, no explanation.

## The Problem

Composing a file from shell commands looks tidy: `echo "header" > out.txt`, then a loop appending lines, then a footer. One `>` typed where `>>` belonged and the file silently restarts from that command; everything before it is gone with no error, no prompt, no undo. The truly destructive variant is self-redirection: `sort data.txt > data.txt` or `grep -v foo config.ini > config.ini`. The shell truncates the output file *before* the command reads it, so the command processes an empty file and writes an empty result — the original content is destroyed by the act of trying to transform it.

AI assistants hit this more than humans do because they build files incrementally across multiple commands, sometimes across multiple tool calls with reconstructed context, where "which commands have already run against this file" is exactly the state that gets lost. And `>` doesn't distinguish "create new" from "destroy existing" — it happily zeroes a file that took an hour to produce.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Clobber Files with Shell Redirection

NEVER redirect a pipeline's output onto its own input file, and never compose a multi-step file with a chain of `>`/`>>` commands when a single write will do.

`>` truncates the target before anything runs: self-redirection empties the input pre-read, and one wrong `>` mid-composition silently discards everything composed so far.

- To transform a file in place: write to a temp file and move it over (`sort data.txt > data.txt.tmp && mv data.txt.tmp data.txt`), or use the tool's in-place mode (`sort -o data.txt data.txt`, `sed -i`). NEVER `cmd file > file`.
- To create a file with known content, write it in one operation: a file-write tool, a single heredoc (`cat > out.txt <<'EOF' ... EOF`), or one `printf`. Multi-command `echo`-chains maximize the chances of a `>`/`>>` slip and leave a partial file if any step fails.
- Before any `>` aimed at an existing file, confirm overwriting is the intent. If you're adding, it's `>>`; if you're replacing, say so to yourself explicitly first.
- `set -o noclobber` in scripts you author makes accidental `>` over an existing file an error (`>|` to override deliberately).
- `tee` reads the same trap: `cmd file | tee file` clobbers too. And `2>file` versus `2>>file` follows the same append/truncate logic for logs.

**Red flags that you're about to violate this:**

- "I'll sort the file and write it right back to itself."
- "Building the file with a series of echo appends keeps each step simple."
- "I'm pretty sure I already wrote the header with >>." (Pretty sure is how files get zeroed.)
- "If I clobber it, I'll just regenerate it." (The input you'd regenerate from may be the thing you clobbered.)
- "It's just a redirect, what could it destroy?"

---

## Why It Works

1. **It teaches the evaluation order that makes self-redirection destructive** — truncation happens before the command reads — so the trap is understood as mechanical, not as bad luck to be avoided by care.
2. **Single-operation writes eliminate the state problem.** A heredoc has no "which step already ran" to misremember; the `echo`-chain failure mode simply has no surface to occur on.
3. **The temp-and-rename idiom is strictly better, not just safer:** it's atomic, it preserves the original until the new version fully exists, and it costs one `&& mv`.

## Origin

A cleanup task deduplicated a hand-maintained list of 4,000 allowed domains with `sort -u allowlist.txt > allowlist.txt`. The file was zero bytes before `sort` read its first line. No backup, not yet committed, and the "source" it could be rebuilt from was a retired spreadsheet. Two engineers spent a day reconstructing the list from proxy logs, and the team's shell snippets doc gained its first bolded entry.
