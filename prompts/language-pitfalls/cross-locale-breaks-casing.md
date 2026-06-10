---
title: Locale Breaks String Casing
slug: cross-locale-breaks-casing
category: language-pitfalls
tags: [universal, cross-language]
works_with: all
severity: high
one_liner: "Stops locale-dependent uppercase and lowercase from breaking comparisons"
---

# Locale Breaks String Casing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents case-insensitive comparisons of protocol strings from failing when the machine's locale turns `I` into `ı` — the Turkish-İ bug and its relatives.

**[Copy-paste ready version](../../install/cross-locale-breaks-casing.md)** — just the instruction block, no explanation.

## The Problem

`"INFO".toLowerCase() == "info"` is true everywhere — until the runtime locale is Turkish, where lowercasing the dotless-uppercase `I` produces `ı` (U+0131), and the comparison fails. Java's `String.toLowerCase()`, `String.format`, and friends are locale-sensitive by default; so are .NET's `ToLower`/`ToUpper` and C's `tolower` under a set locale. Code that case-folds HTTP headers, file extensions, enum names, language tags, or config keys works on every developer machine and breaks on any machine whose OS locale has special casing rules (Turkish and Azerbaijani for I/i, Lithuanian for dot-above). The reverse direction also corrupts data: uppercasing `"mail"` in a Turkish locale yields `"MAİL"`.

The sibling trap is locale-sensitive formatting: `String.format("%f", 1.5)` produces `"1,5"` under many European locales, and that comma then fails to parse downstream, breaks CSV column counts, or gets stored as a corrupt numeric string. Same code, same input, different machine, different bytes.

Assistants generate bare `toLowerCase()`/`format` calls because the overloads without a locale argument are the common ones in training data, and because on the author's machine — and the CI machine — the default locale is almost always English-ish, so nothing ever fails before production in the wrong country.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Locale Breaks String Casing

ALWAYS use locale-independent casing and formatting for machine-facing strings (protocol tokens, headers, extensions, enum/config keys, serialized numbers). Default casing and formatting follow the process locale, so the same code produces different bytes on different machines — the Turkish-İ bug.

- Java: `toLowerCase(Locale.ROOT)` / `toUpperCase(Locale.ROOT)`; `String.format(Locale.ROOT, ...)` for serialized numbers. Bare `toLowerCase()` on a token is a latent bug.
- .NET: `ToLowerInvariant()` / `ToUpperInvariant()`; compare with `StringComparison.OrdinalIgnoreCase`; format/parse with `CultureInfo.InvariantCulture`.
- Python/Go/JS default casing is not locale-driven (safer default), but JS has `toLocaleLowerCase` and Python has locale-aware formatting — don't reach for those for machine strings. For Unicode-correct case-insensitive matching of *human* text, use case folding (`str.casefold()` in Python), not lowercase.
- Case-insensitive token comparison shouldn't case-convert at all where an ordinal-ignore-case comparison exists (`equalsIgnoreCase` in Java is locale-safe for this; `strings.EqualFold` in Go).
- Serializing numbers and dates for files, APIs, and logs: always invariant/ROOT locale. `"1,5"` where a parser expects `"1.5"` is this bug in formatting clothes.
- Locale-aware casing and formatting are correct for text *displayed to users* — that's what the locale-sensitive APIs are for. The rule is about strings consumed by software.
- Don't fix this by setting the process default locale to English: that breaks actual localization and is a global mutable setting. Fix the call sites.

**Red flags that you're about to violate this:**

- "toLowerCase is a pure function of the string."
- "It passes on CI, casing is deterministic."
- "Nobody runs servers in a Turkish locale." (JVMs and desktops inherit OS locales everywhere your users are.)
- "I'll normalize with toUpperCase before comparing — uppercase is safe." (Turkish uppercases i to İ.)
- "I'll just set the default locale to en-US at startup."
- "%f formatting always uses a decimal point."

---

## Why It Works

1. **It splits strings into machine-facing and human-facing.** The model's confusion is applying one casing concept to both; the rule makes the audience of the string decide the API, which resolves every call site mechanically.
2. **It corrects "casing is pure."** The false belief enabling the bug is that case conversion depends only on the input string; naming the hidden locale parameter makes the nondeterminism visible.
3. **It blocks both bad fixes.** Uppercase-instead (fails the same way in reverse) and set-global-locale (breaks localization) are the two repairs models reach for; pre-empting them channels the fix to the call site.
4. **It includes number formatting.** The `"1,5"` variant is the same mechanism wearing different syntax; covering it prevents the model from learning the casing rule narrowly.

## Origin

A document pipeline matched file types with `extension.toUpperCase().equals("PDF")` on the JVM. A customer deployment in Istanbul inherited the OS locale; `"pdf"` uppercased to `"PDF"` with a dotted İ — not equal — and every PDF was routed to the "unsupported format" bin. Support spent days on it because the vendor could not reproduce: same build, same files, same everything, except the one input nobody lists in a bug template — the server's locale.
