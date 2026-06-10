---
title: Don't Slurp Huge Files to Change One Line
slug: dont-slurp-huge-files
category: file-handling
tags: [universal, files, performance]
works_with: all
severity: medium
one_liner: "Stops whole-file reads of gigabyte logs and data to touch a few bytes"
---

# Don't Slurp Huge Files to Change One Line

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents reading enormous files fully into memory — or into context — to inspect or modify a tiny portion of them.

**[Copy-paste ready version](../../install/dont-slurp-huge-files.md)** — just the instruction block, no explanation.

## The Problem

The habit that works on source files — read the whole thing, think, write the whole thing — gets pointed at a 4 GB log, a 900 MB CSV export, a database dump, or a JSONL training set. As code, `data = open(path).read()` OOMs the process or grinds a laptop to swap; the streaming equivalent would have used constant memory. As an assistant workflow, dumping a huge file into context truncates it silently, floods the conversation with noise, and burns the budget that the actual task needed — often just to confirm a header row or find one matching line.

The write side is worse than the read side. Slurp-modify-rewrite on a huge file means a multi-gigabyte write to change one record, minutes of I/O, and a long window where the file on disk is half-written. Tools exist precisely for this: `sed -i` streams an in-place line edit, `grep -n` finds the offset without reading past it, and every language can iterate lines lazily. Assistants reach for full reads because file size is invisible until they check, and they don't check.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Slurp Huge Files to Change One Line

ALWAYS check a file's size before reading it whole. Past a few megabytes, switch from load-everything to stream-or-sample.

Whole-file reads scale with the file; the task usually doesn't. A one-line change to a 4 GB file should cost roughly one line of I/O and memory, not 4 GB.

- Check first: `ls -lh <path>` or `du -h <path>`. Make size a fact, not a surprise.
- To inspect: `head`, `tail`, `wc -l` for shape; `grep -n <pattern>` to locate; `sed -n '100,140p'` to view a region. Never cat a large file into your context to "look around."
- To edit: `sed -i 's/old/new/'` for line-level changes; `awk` for columnar work; for structured big data, streaming parsers (`jq -c` over JSONL, `csv` readers row-by-row), not `json.load` on a 2 GB file.
- In code you write, default to iteration for unbounded inputs: `for line in f:` (Python), `readline`/streams (Node), `bufio.Scanner` (Go, mind the token limit). Reserve `read()`/`readFileSync` for files you know are small — configs, source files.
- Logs, dumps, exports, fixtures with `data` in the path, and anything user-uploaded are unbounded until proven otherwise.
- If the task truly needs full-file processing (sorting, global dedup), say so and use disk-backed tools (`sort`, `split`) rather than RAM.

**Red flags that you're about to violate this:**

- "I'll read the file and see what's in it." (How big is it?)
- "json.load is the normal way to read JSON."
- "It worked on the test file." (The test file was 2 KB; production is 2 GB.)
- "I need the whole file to change line 30,000." (sed disagrees.)
- "Memory is cheap." (Not at 3 a.m. when the box is swapping.)

---

## Why It Works

1. **The size check converts an invisible property into a branch point.** Almost every slurp disaster begins with not knowing the number; `ls -lh` makes the wrong path require ignoring evidence.
2. **It maps each intent to a constant-memory tool** — locate, view, edit, transform — so streaming isn't a discipline, it's a lookup table.
3. **The "unbounded until proven otherwise" classification fixes the test-vs-production gap:** code is validated against small fixtures and deployed against the real distribution, which is exactly when `read()` stops being a style choice and becomes an outage.

## Origin

An import endpoint parsed uploaded CSVs with a full `read().split("\n")` — fine for the 50-row file in the test suite. A customer uploaded an 1.8 GB export; the worker OOM'd, the orchestrator restarted it, the customer's client retried the upload, and the loop pinned the service in a crash-restart cycle until someone rate-limited the customer and rewrote the parser to stream.
