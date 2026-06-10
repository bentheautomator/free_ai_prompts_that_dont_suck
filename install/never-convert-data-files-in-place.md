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
