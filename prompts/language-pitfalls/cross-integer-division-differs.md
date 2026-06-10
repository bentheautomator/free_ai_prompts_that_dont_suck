---
title: Integer Division Differs by Language
slug: cross-integer-division-differs
category: language-pitfalls
tags: [universal, cross-language]
works_with: all
severity: high
one_liner: "Stops ported division and modulo from changing value, sign, or type"
---

# Integer Division Differs by Language

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents `/` and `%` from silently meaning different things when code moves between Python, JS, Go, C, and SQL — especially on negative numbers.

**[Copy-paste ready version](../../install/cross-integer-division-differs.md)** — just the instruction block, no explanation.

## The Problem

`7 / 2` is `3.5` in Python 3 and JavaScript, `3` in Go, C, Java, and most SQL dialects. `-7 / 2` is where it gets properly hostile: Python's `//` floors toward negative infinity (`-4`), while Go, C, Java, and JS's `Math.trunc` truncate toward zero (`-3`). Modulo follows its division: `-7 % 2` is `1` in Python (sign of the divisor) but `-1` in Go, C, and JavaScript (sign of the dividend). Any code that buckets values — pagination, hash slots, time windows, circular indices — gives different answers for negative inputs depending on which language convention it inherited.

The failure is a porting failure. An algorithm written against Python's floor semantics, translated line-by-line into Go or JS with the "same" operators, is correct for all positive test inputs and wrong for every negative one. `items[i % n]` from Python becomes an index-out-of-range crash (or a negative array read) in JS the first time `i` goes negative. Timestamp bucketing before the epoch, offsets going backward, deltas that dip below zero — all quiet correctness bugs.

Assistants are translation machines, and operator-for-operator translation is their default. The model maps `//` to `/`, `%` to `%`, sees the tests pass on positive numbers, and moves on. Nothing in the syntax signals that the semantics changed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Integer Division Differs by Language

NEVER port division or modulo between languages operator-for-operator without checking semantics for (a) integer vs float division and (b) behavior on negative operands. The operators look identical and aren't.

- Division type: `7/2` is `3.5` in Python 3 and JS, `3` in Go/C/Java/Rust and most SQLs when both operands are integers. When porting, decide which result the algorithm needs and make it explicit: `//` or `math.floor` in Python, `Math.floor`/`Math.trunc` in JS, plain `/` on ints elsewhere.
- Negative rounding direction: Python `//` floors (`-7 // 2 == -4`); Go/C/Java/Rust/JS truncate toward zero (`-3`). Different answers whenever signs differ.
- Modulo sign: Python `%` returns the divisor's sign (`-7 % 2 == 1`); Go/C/Java/JS return the dividend's sign (`-7 % 2 == -1`). Rust has both (`%` truncates; `rem_euclid` floors). SQL dialects vary.
- Circular indexing with possibly-negative values: `arr[i % n]` is only safe under floor-mod. Portable form: `((i % n) + n) % n`, or the language's euclidean-mod function. Use it whenever `i` can be negative.
- Bucketing/windowing (timestamps into intervals, ids into shards): pick floor semantics explicitly so values below the origin land in the correct lower bucket, and implement it per the target language, not per the source syntax.
- JS extra: `%` works on floats too (`5.5 % 2 === 1.5`) and `x | 0`-style integer tricks break beyond 32 bits — don't use bitwise ops as integer division.
- When writing the port, add a test with a negative operand. It is the single test that distinguishes every convention above.

**Red flags that you're about to violate this:**

- "Modulo is modulo, the operator is the same in both languages."
- "I translated it line by line, the logic is unchanged."
- "Indices here are always positive." (Deltas, offsets, and pre-epoch timestamps would like a word.)
- "The tests pass." (With all-positive fixtures.)
- "I'll round the division at the end; direction doesn't matter."

---

## Why It Works

1. **It attacks translation-by-syntax directly.** The model's porting procedure maps tokens, not semantics; declaring `/` and `%` as false cognates forces a semantic check exactly where the procedure skips it.
2. **It reduces the mess to two questions.** Int-vs-float and negative-direction cover every variant; a two-item checklist gets applied where a semantics lecture wouldn't.
3. **It supplies the portable idiom.** `((i % n) + n) % n` is the known-good escape hatch for the most common concrete bug (circular indexing), so the fix doesn't require re-deriving number theory.
4. **It mandates the one discriminating test.** A single negative-operand test case mechanically distinguishes all the conventions — turning a subtle review judgment into a fixture.

## Origin

A scheduling library's "week number" logic was ported from Python to TypeScript for a frontend preview feature. Dates before the reference epoch produced negative day counts; Python's floor division had bucketed them correctly, while the TS translation truncated, shifting every pre-epoch date one week forward. The backend and the preview disagreed only for recurring events created before 2020 — reported, naturally, as "calendar is haunted," and triaged for a month as a timezone bug. It wasn't a timezone bug. It was one `/`.
