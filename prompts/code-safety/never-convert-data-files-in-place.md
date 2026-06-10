---
title: Never Convert Data Files in Place
slug: never-convert-data-files-in-place
category: code-safety
tags: [universal, files, data]
works_with: all
severity: critical
one_liner: "AI overwriting originals with lossy or failed format conversions"
---

# Never Convert Data Files in Place

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from replacing original data files with converted, compressed, or re-encoded versions that lose information.

**[Copy-paste ready version](../../install/never-convert-data-files-in-place.md)** — just the instruction block, no explanation.

## The Problem

"Convert these TIFFs to JPEG to save space" — and the AI writes a loop that converts each file and deletes the original, or worse, writes the JPEG over the TIFF's filename. The conversion is lossy. The originals were scans of documents that can't be re-scanned. The "space savings" cost the archive its source material. Same story with different nouns: re-encoding video, downsampling audio, flattening layered images, converting XLSX to CSV (goodbye formulas, sheets, and types), pretty-printing JSON with a parser that drops unknown fields, normalizing CSVs with a tool that mangles encodings and date formats.

Two distinct failures hide here. First, lossy-by-design: the target format genuinely holds less, and once the original is gone the information is unrecoverable. Second, lossy-by-bug: the conversion *should* be faithful but the tool chokes on an edge case — encoding, a huge cell, a malformed row — and corrupts silently. In-place conversion means both failures destroy the only copy. The AI converts in place because it optimizes for tidiness: one set of files, no "duplicates," task looks complete. Tidiness is a terrible reason to lose data.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Convert Data Files in Place

NEVER overwrite or delete original data files as part of a format conversion, re-encoding, compression, or normalization. Convert to new files, verify the results, and let the user decide when (or whether) originals get removed.

The core problem: conversions lose information two ways — by design (lossy formats, flattened structures, dropped metadata) and by bug (encoding issues, edge-case rows, tool quirks) — and in-place conversion makes either failure destroy the only copy.

- Write converted output to new paths: a parallel directory (`converted/`) or a new extension. Never reuse the original's filename, never `--delete-source` flags, never `convert x.tiff x.jpg && rm x.tiff` in one breath.
- Before converting, state what the target format cannot represent: image quality and layers, audio fidelity, spreadsheet formulas and multiple sheets, JSON key order or comments, EXIF/metadata. If something is lost by design, the user approves that loss explicitly.
- Verify after converting, before anyone deletes anything: file counts match, sizes are plausible (a 2 KB output from a 40 MB input is a failed conversion, not a great compression), spot-open several outputs, compare record counts for tabular data.
- Treat originals as untouchable until the user has confirmed the converted set is good — ideally after actually using it.
- For "save disk space" requests, present the math (current size, converted size, what's lost) and let the user choose, rather than choosing for them.

**Red flags that you're about to violate this:**
- "I'll convert and clean up the originals in one pass..."
- "Keeping both copies doubles the disk usage, that defeats the point..."
- "The conversion is lossless enough..."
- "The tool ran without errors, the outputs must be fine..."
- "They asked for JPEGs, so the TIFFs are no longer needed..."

---

## Why It Works

1. **It separates the two losses.** AI assistants only model the by-design loss ("JPEG is fine for this"). Naming lossy-by-bug — silent corruption on edge cases — justifies keeping originals even when the format choice is sound.

2. **It makes deletion a user decision with a timeline.** "After the user has confirmed, ideally after using the converted set" pushes the irreversible step past the point where problems would have surfaced.

3. **It demands articulated loss.** Forcing the AI to list what the target format can't represent surfaces the formulas, the layers, the metadata — the things "convert these files" never mentioned but the user would have vetoed losing.

## Origin

Asked to shrink a folder of survey data exports, an assistant converted XLSX workbooks to CSV and deleted the originals to realize the savings. Each workbook had three sheets; CSV kept the first. The second sheet held the response-code legend without which the data was uninterpretable. The vendor who'd produced the exports had a 30-day retention policy, and it was day 41.
