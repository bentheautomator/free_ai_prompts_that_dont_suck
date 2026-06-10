---
title: Stream Large Files Instead of Slurping Them
slug: stream-large-files-instead-of-slurping
category: performance
tags: [universal, performance, memory]
works_with: all
severity: high
one_liner: "Stops reading whole files into memory to use one row or one field"
---

# Stream Large Files Instead of Slurping Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from loading an entire file or dataset into memory when it only needs a slice of it.

**[Copy-paste ready version](../../install/stream-large-files-instead-of-slurping.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI assistant to "find the user's row in the export" and it writes `data = json.load(open("export.json"))` or `lines = file.read().split("\n")`, then loops to find one record. On the 2 MB test fixture this works instantly. On the 4 GB production export, the process eats all available memory, the OS starts swapping, and the container gets OOM-killed before the loop runs once. The code was correct; the loading strategy was the bug.

AI assistants default to slurping because whole-file reads are the shortest code and the dominant pattern in training data, where examples are toy-sized. `readFileSync`, `pd.read_csv` with no chunking, `file.readlines()`, `json.load` on a multi-gigabyte log — each is one line, each looks idiomatic, and each assumes the file fits in RAM with room to spare. The assistant never sees the file size, so it never weighs the assumption.

The failure is silent until it isn't. Memory usage scales with the input the *user* provides, not the input the developer tested. The first oversized upload becomes a production incident, and the stack trace points at the allocator, not at the line that decided to buffer everything.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Stream Large Files Instead of Slurping Them

NEVER read an entire file or dataset into memory when the task needs only part of it, a single pass over it, or an aggregate of it. Memory use must be bounded by what you keep, not by what you read.

Whole-file reads are correct only when the file is known to be small and bounded (a config file, a template). For anything user-supplied, log-shaped, export-shaped, or of unknown size, assume it does not fit in RAM.

- Process line-by-line or record-by-record: iterate the file handle, use streaming JSON/CSV parsers (`ijson`, `csv.reader` over a handle, `pd.read_csv(chunksize=...)`, Node streams) instead of `read()`, `readlines()`, `readFileSync`, or `json.load` on the whole thing.
- If you need one record, stop reading when you find it. Do not load everything and then search.
- If you need an aggregate (count, sum, max), accumulate it in a single pass with O(1) state.
- If you genuinely need random access to a huge file, say so and propose an index, byte offsets, or a database — not a giant in-memory structure.
- Before choosing a loading strategy, state the size assumption out loud: "this file is bounded because X" or "this is unbounded, so I'm streaming." If you can't justify "bounded," stream.
- Verify with realistic scale: check memory behavior against an input at least the size of real production data, not the test fixture.

**Red flags that you're about to violate this:**
- "Reading the whole file is simpler and files are usually small."
- "I'll load it all first, then filter — easier to reason about."
- "The test data is only a few hundred lines."
- "Parsing the whole JSON is the idiomatic way."
- "Memory is cheap; this is fine."

**

## Why It Works

1. **It reframes the invariant.** "Memory bounded by what you keep, not what you read" gives the AI a checkable property instead of a vague preference, so any accumulate-everything pattern visibly violates the rule.
2. **It forces the size assumption to be stated.** Slurping is only wrong when the file can be big; making the assistant justify "bounded" surfaces the unstated assumption that test data represents production data.
3. **It names the exact APIs.** `readFileSync`, `readlines()`, `json.load` are the pattern-matched defaults; listing them as suspects interrupts autocomplete-by-habit and points at the streaming equivalent.
4. **It closes the "find then stop" loophole.** Without the early-exit clause, assistants stream the file but still buffer every record "just in case."

## Origin

A data team's import endpoint accepted CSV uploads and worked flawlessly for months. The handler, written by an assistant, did `rows = list(csv.reader(io.StringIO(body.decode())))` before validating anything. A customer uploaded an 11 GB export; three worker pods OOM-killed in rotation as the load balancer retried the request against each one, taking the whole import service down for everyone. The streaming rewrite was 14 lines and held memory flat at any file size.
