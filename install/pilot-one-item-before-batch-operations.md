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
