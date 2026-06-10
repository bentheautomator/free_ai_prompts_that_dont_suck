---
title: Pilot One Item Before Batch Operations
slug: pilot-one-item-before-batch-operations
category: code-safety
tags: [universal, automation, data]
works_with: all
severity: high
one_liner: "AI running an untested transform across hundreds of files in one shot"
---

# Pilot One Item Before Batch Operations

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from discovering a bug in its processing logic only after that logic has touched every file.

**[Copy-paste ready version](../../install/pilot-one-item-before-batch-operations.md)** — just the instruction block, no explanation.

## The Problem

The AI writes a loop to process 800 files — resize, reformat, fix headers, restructure front matter — and runs it on all 800 first try. The logic has a bug that only shows on files with a BOM, or multi-line headers, or Windows line endings. Now the bug's output is distributed across 800 files, interleaved with correct output, and "which files did it mangle?" is a forensic project. If the transform wrote in place, the originals are gone too. One test file would have caught it; instead the first full execution *was* the test, run against the entire population.

AI assistants skip piloting because their code feels done: it parsed correctly, it handles the cases they thought of, and the loop is sitting right there. But batch operations have a brutal property — the cost of a logic bug scales with the number of items already processed when you notice. Running item #1 alone prices that bug at one item. Running all 800 prices it at 800. Same bug, same code; the only variable is whether you looked at one output before producing the rest.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Pilot One Item Before Batch Operations

NEVER run a new batch operation against the full set on its first execution. Process one item, verify the output by actually inspecting it, then a small batch (5-10), then the rest. The first run of any transform is a test, and tests don't get run against the whole population.

The core problem: a bug in batch logic costs one item if you catch it on item one, and the whole set if you catch it at the end. Edge cases (encodings, odd formats, surprise structures) live in real data, not in the cases you imagined while writing the loop.

- Pilot on one item: run the transform on a single representative input. Open the output. Compare against the input. "It exited zero" is not verification — look at the content.
- Then a small batch including the *weird* items: the biggest file, the oldest, one with unicode in the name, one in each format variant. Edge cases cluster in outliers, so test the outliers.
- Only then the full run — and keep it observable: progress output, a log of items processed, and ideally outputs to a new location so the run is comparable against the originals.
- Never make the first full run an in-place run. Write outputs separately or back originals up until after spot-checking the batch results (count outputs, sample several, compare totals).
- If the pilot or small batch surprises you at all — output differs from expectation, even harmlessly — fix and re-pilot. Surprises at N=5 are bugs at N=800.
- This applies to every batch shape: file loops, API-record processing, image/video conversion, bulk file edits, data cleaning scripts.

**Red flags that you're about to violate this:**
- "The logic is straightforward, I'll run it on everything..."
- "I already tested mentally against the format spec..."
- "Running one first then all of them is just running it twice..."
- "If something's wrong, the errors will show in the output..."
- "These files are all identical in structure anyway..."

---

## Why It Works

1. **It reprices the bug.** "Cost scales with items processed before noticing" turns piloting from cautiousness into arithmetic — the AI can't argue with one-item bugs being 800x cheaper than full-set bugs.

2. **It defines verification as inspection.** AI assistants verify by exit code. "Open the output, compare against the input" replaces the false signal (ran without errors) with the real one (produced correct content).

3. **It aims the pilot at outliers.** Random sampling misses the edge cases that break batch logic; explicitly piloting the biggest/oldest/weirdest items puts the probe where the failures actually live.

## Origin

An assistant wrote a script to normalize front matter across a documentation repo — about 600 markdown files — and ran it across the whole tree in one pass, in place. The parser misread any file whose front matter contained a colon inside a quoted string, truncating the body. Roughly 70 files were silently gutted, scattered among 530 correct ones. The team found them over the next two weeks, one confused reader at a time. The very first file in the repo, alphabetically, would have triggered the bug as a pilot.
