### Build Big Strings with Buffers, Not Concatenation

NEVER build a large or unbounded-size string by repeated concatenation (`+=`, `s = s + piece`) in a loop. With immutable strings each append copies everything accumulated so far, making total cost quadratic in output size. Collect parts and join once, or write to a buffer/stream.

- Python: append to a list and `"".join(parts)` at the end, or use `io.StringIO`. Java/C#: `StringBuilder`. Go: `strings.Builder`. JavaScript: push to an array and `join("")` for large outputs.
- For output that leaves the process anyway (HTTP response, file), don't materialize the whole string at all; write pieces to the response/file stream as you go.
- The same quadratic structure applies to collections: `list = list + [item]` and repeated `arr.concat(x)` copy the whole accumulator per iteration. Use in-place `append`/`push`.
- Small, fixed-count concatenations are fine: gluing five known fragments together is not the problem. The rule triggers when the iteration count is data-sized (rows, lines, records, user items).
- f-strings/template literals composing one line are fine; the trap is accumulating many lines via `+=`.
- Verify with scale, not eyeballs: time the builder at 1k items and at 100k items. Linear means roughly 100x the time; if it's wildly more than that, you've got the quadratic. For a one-line check, the loop body containing `accumulator += ...` on a string is the smell.

**Red flags that you're about to violate this:**
- "+= is the most readable way to append."
- "Modern runtimes optimize string concatenation anyway."
- "The output is usually small."
- "A StringBuilder is overkill for this."
- "The tests pass and the output is correct."
- "I'll keep it simple now and optimize if it's slow." (it will be, at exactly the worst time)
