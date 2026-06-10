---
title: Avoid Catastrophic Regex Backtracking
slug: avoid-catastrophic-regex-backtracking
category: performance
tags: [universal, performance, regex]
works_with: all
severity: critical
one_liner: "Stops regexes whose nested quantifiers melt a CPU core on hostile input"
---

# Avoid Catastrophic Regex Backtracking

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from writing regexes with nested or ambiguous quantifiers that take exponential time on inputs that almost match.

**[Copy-paste ready version](../../install/avoid-catastrophic-regex-backtracking.md)** — just the instruction block, no explanation.

## The Problem

A regex like `^(\w+\s?)+$` or `(a+)+b` or the classic AI-generated email validator `^([a-zA-Z0-9_.+-]+)+@...` looks fine, passes every test with valid input, and matches in microseconds. Then someone submits a string that *almost* matches — 40 words and a trailing exclamation mark — and the backtracking engine starts exploring every possible way to partition the input between the nested quantifiers. The possibilities are exponential. The match attempt that took 0.2ms on valid input takes 45 seconds on the near-miss, pegging a CPU core the entire time. In an event-loop runtime, the whole process is gone. This is ReDoS, and it's a one-string denial of service.

AI assistants are prolific producers of these patterns because they assemble regexes from familiar fragments — `(\s*...\s*)*`, `(.+)+`, alternations with overlapping branches like `(\w|\d)+` — without modeling the backtracking engine underneath. The hostile input never appears in tests, because tests check that valid things match and invalid things don't; nobody tests that invalid things fail *fast*.

The trap is sprung specifically by attacker- or user-controlled input hitting the pattern, which is exactly where validation regexes live: form fields, URL parsers, log scanners, markdown processors.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Avoid Catastrophic Regex Backtracking

NEVER apply a regex with nested quantifiers, quantified groups containing quantifiers, or overlapping alternations to user-controlled input. On a backtracking engine these patterns take exponential time on inputs that nearly match, and one crafted string can peg a CPU core for minutes.

The danger shapes, learn them on sight: `(x+)+`, `(x*)*`, `(x+)*`, `(x|xy)+`, `(\s*,\s*)*`, and any group where the same character could be consumed by either of two adjacent quantifiers (`\w+\s?` repeated, `.*.*`).

- Make repetition unambiguous: each character of input should have exactly one way to be consumed. Prefer explicit character classes with single quantifiers (`[\w.+-]+@[\w-]+\.[\w.]+`) over quantified groups of quantified things.
- Anchor patterns and bound repetition where the domain allows (`{1,64}` instead of `+` for an email local part). Bounded repetition caps the search space.
- Length-limit the input before the regex runs. A 100-character cap turns a theoretical exponential into a non-event.
- Where available, prefer a non-backtracking engine for user input: RE2, Rust's `regex`, Go's `regexp`, .NET's `NonBacktracking` flag, or a regex timeout if the platform offers one.
- Often the honest fix is not using a regex: `split`, `startsWith`, or a real parser for emails/URLs (the platform has one).
- Verify with a near-miss test: run the pattern against a long input that almost matches (e.g., 50 repetitions of the repeated unit plus one breaking character) and assert it completes in milliseconds. Matching valid input fast proves nothing; failing fast is the property under test.

**Red flags that you're about to violate this:**
- "This regex passes all the test cases."
- "Nesting the group keeps the pattern readable."
- "Nobody would ever input a string like that."
- "Regex performance is the engine's problem."
- "I'll combine these two patterns into one with an outer `+`."
- "It's just a validation regex, how slow can it be?"

---

## Why It Works

1. **It teaches the shapes, not the theory.** The AI won't simulate a backtracking engine, but it can pattern-match `(x+)+` and friends as forbidden forms, which catches the vast majority of real ReDoS patterns.
2. **It states the one-way-to-consume invariant.** "Each character has exactly one consumer" is a constructive rule for writing safe patterns, not just a list of bad ones.
3. **It adds the missing test category.** Tests normally assert what matches; requiring a fail-fast assertion on a long near-miss tests the exact property that catastrophic patterns violate.
4. **It offers cheap structural outs.** Length caps, bounded quantifiers, and non-backtracking engines fix the problem even when pattern review misses something, so safety doesn't depend on perfect regex authorship.

## Origin

A signup form's "no consecutive spaces" check used `^(\w+\s?)+$` server-side. A user pasted a bio that ended in an emoji: 60 words, then a character `\w` wouldn't match. The Node process spent 70 seconds backtracking, the event loop froze, the load balancer marked the instance dead, and the retry storm fed the same string to the next instance. The fleet went down one pod at a time, in order, like dominoes. The post-incident fix was a 256-character length cap and a pattern rewrite, plus a regression test asserting the near-miss string fails in under 10ms.
