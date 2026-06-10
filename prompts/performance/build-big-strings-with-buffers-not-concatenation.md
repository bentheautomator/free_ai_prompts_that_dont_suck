---
title: Build Big Strings with Buffers, Not Concatenation
slug: build-big-strings-with-buffers-not-concatenation
category: performance
tags: [universal, performance, memory]
works_with: all
severity: high
one_liner: "Stops += string building in loops that turns linear work quadratic"
---

# Build Big Strings with Buffers, Not Concatenation

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from assembling large strings with repeated concatenation in loops, where immutable-string copying makes the cost quadratic.

**[Copy-paste ready version](../../install/build-big-strings-with-buffers-not-concatenation.md)** — just the instruction block, no explanation.

## The Problem

`result += line` inside a loop reads like appending. In languages with immutable strings (Python, Java, C#, and effectively many JS engine paths), it's copying: each `+=` allocates a new string and copies everything accumulated so far, plus the new piece. Appending n pieces costs 1+2+3+...+n copies of growing prefixes — quadratic, not linear. Building a 100-row CSV this way is instant. Building a 500,000-row export copies hundreds of gigabytes of intermediate strings through the allocator, takes minutes of pure CPU, and triggers GC storms along the way.

AI assistants generate this constantly because `+=` is the most natural-reading way to express "add to the output," and every example in training data builds small strings where the quadratic term is invisible. The code is *correct* — output is byte-identical to the fast version — so no test catches it. Only scale does.

The same trap wears other costumes: `result = result + chunk` in report generators, `html += "<tr>..."` in server-side renderers, `sql += clause` in query builders, and repeated `array.concat()` or `list = list + [item]` building big collections, which has the same copy-everything-each-time structure.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It exposes the hidden copy.** The AI reads `+=` as O(1) append; restating it as "copies everything accumulated so far" attaches the real cost model to the operator.
2. **It supplies the idiomatic replacement per language.** Join/StringBuilder/StringIO are equally short, so the rule never asks the AI to trade readability, removing the main excuse.
3. **It scopes by iteration count, not by operator.** Allowing fixed small concatenations keeps the rule from degrading into noise that gets ignored.
4. **It verifies with a scaling ratio.** Comparing 1k vs 100k items detects the quadratic directly, catching cases where the pattern hid behind a helper function.

## Origin

A nightly job assembled a partner data feed by looping rows and doing `feed += format_row(row)`. At 30,000 rows it took 40 seconds and nobody looked twice. The partner's catalog grew to 800,000 rows over a year, and the job's runtime grew to four hours, blowing past its window and shipping stale feeds — the runtime chart over twelve months was a textbook parabola. Changing four lines to append-to-list-then-join brought it to 90 seconds. The engineer's commit message: "n squared, n got big."
