---
title: Regex Dialects Are Not Portable
slug: cross-regex-dialects-differ
category: language-pitfalls
tags: [universal, cross-language]
works_with: all
severity: high
one_liner: "Stops regexes copied across languages from silently matching differently"
---

# Regex Dialects Are Not Portable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a regex that worked in one language from misbehaving in another — different escapes, anchors, defaults, and feature sets, often with no error to warn you.

**[Copy-paste ready version](../../install/cross-regex-dialects-differ.md)** — just the instruction block, no explanation.

## The Problem

"Regex" is not one language; it's a family of dialects that agree on the easy parts. Move a pattern from Python to JavaScript to Go to `grep` and the same string of characters can mean different things — or fail to compile, which is the *good* outcome. The bad outcomes are silent: Python's `re.match` anchors at the start of the string while JS `.match` searches anywhere, so a validation regex ported verbatim stops validating. `$` in Python matches before a trailing newline; combine that with multiline flags differing and "end of input" means three different things across runtimes. Go's RE2 and `grep -E` have no lookahead/lookbehind or backreferences at all — and a model porting a PCRE pattern to Go will sometimes "adapt" it into a pattern that compiles but matches something else.

Then there are the within-pattern traps that change per dialect: `\d` matches all Unicode digits in Python 3 (including `٣`) but ASCII-only in JS without the `u`/`v` flags' interactions; character-class escaping rules differ; shell single-vs-double quoting mangles backslashes before the regex engine ever sees them; and case-insensitivity flags are spelled `(?i)`, `/i`, or `re.I` depending on where you are.

Assistants treat regexes as language-independent strings — they'll copy a pattern between files in different languages as if it were data. It looks like data. It's code in a dialect.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Regex Dialects Are Not Portable

NEVER copy a regex between languages or tools as if it were plain data. Regex dialects differ in anchoring, escapes, character-class semantics, and supported features; a ported pattern can compile and silently match differently.

- On every port, re-verify three things: anchoring (Python `re.match` anchors at start, `re.fullmatch` both ends, JS/Go search anywhere — add explicit `^...$` or `\A...\z` per the target's rules), flags (how the target spells case-insensitive, multiline, dotall), and feature support.
- For validation, prefer explicit full anchors in the pattern itself rather than relying on the host function's anchoring behavior — it makes the intent portable.
- `$` is not "end of string" everywhere: in several engines it also matches before a final newline; use `\z` (or the target's equivalent) when trailing-newline acceptance matters, e.g. validating user input.
- Feature gaps: Go (RE2), POSIX `grep`/`sed`, and RE2-based services have no lookahead, lookbehind, or backreferences. Do not approximate such patterns — restructure the logic (multiple matches plus code) and say so.
- `\d`, `\w`, `\s` are Unicode-aware in some engines (Python 3) and ASCII in others (Go, JS without flags). If you mean `[0-9]`, write `[0-9]`.
- Shell contexts mangle patterns before the engine sees them: backslashes and `$` inside double quotes, BRE vs ERE in `grep` vs `grep -E`, `sed`'s escaping of `+` and `?` in BRE. Test the pattern *in* the shell context, not just in a regex playground set to PCRE.
- After porting, run the target-language pattern against a small fixture set including the edge cases: empty string, trailing newline, multiline input, non-ASCII digits/letters.

**Red flags that you're about to violate this:**

- "A regex is a regex; I'll reuse the one from the Python service."
- "It compiles in the new language, so the port worked."
- "re.match and string.match do the same thing."
- "I'll emulate the lookbehind with something close enough."
- "The playground says it matches." (The playground is running a different engine than your code.)

---

## Why It Works

1. **It reclassifies regexes from data to code.** The model copies patterns across files the way it copies constants; declaring them dialect-bound code triggers the translation checks it already knows to apply to code.
2. **It names the three silent divergences.** Anchoring, flags, and escapes cover the failures that don't throw; a finite checklist gets executed where "be careful with regex" evaporates.
3. **It forbids approximating missing features.** The worst port is the lookbehind "adapted" for RE2 into a wrong-but-compiling pattern; requiring restructuring-with-disclosure removes the quiet degradation option.
4. **It moves verification into the target context.** Playground-validated patterns fail in shells and other engines; testing in situ with edge-case fixtures checks the thing that actually runs.

## Origin

An allowlist validator for webhook URLs was ported from a Python service to its new Go gateway. The Python pattern relied on `re.match`'s implicit start anchor and a lookahead; the Go version got the lookahead "simplified" away and no anchor added. The result matched the allowed domain anywhere in the URL, so `https://evil.example/?next=allowed-domain.com` sailed through. It compiled, the happy-path tests passed, and the gap was found by a security researcher rather than a unit test — the expensive way to learn that regexes have dialects.
