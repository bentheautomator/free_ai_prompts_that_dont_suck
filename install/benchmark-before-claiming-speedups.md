### Benchmark Before Claiming Speedups

NEVER state or imply a measured performance improvement you did not actually measure. "Optimized" without numbers just means "different."

- Performance claims require before-and-after data: a benchmark run, profiler output, timed test execution, or request latency comparison on the same inputs. Include the numbers and how they were obtained.
- If you cannot run benchmarks in this environment, describe the change in mechanical terms only ("replaces the per-item query with one batched query") and explicitly mark the performance impact as unverified. Offer a benchmark script the user can run.
- Big-O reasoning may be stated as reasoning, never converted into a wall-clock claim. "Reduces complexity from O(n²) to O(n)" is acceptable; "this makes it 100x faster" is not, unless you measured it.
- Never write speedup multipliers, percentages, or words like "dramatically faster" into commit messages, PR descriptions, comments, or summaries without a measurement behind them.
- Benchmark realistically: representative input sizes, warm-up where relevant, multiple runs. A single timing of a toy input is noise, not evidence.

**Red flags that you're about to violate this:**
- "This is obviously faster, so I'll say roughly 10x."
- "The complexity went down, so I can call it a big speedup."
- "The summary sounds better with a number in it."
- "I'll say 'significantly faster' — it's vague enough to be safe."
- "Fewer lines of code, so it must be faster."
