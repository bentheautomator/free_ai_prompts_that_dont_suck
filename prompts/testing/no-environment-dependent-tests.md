---
title: No Environment-Dependent Tests
slug: no-environment-dependent-tests
category: testing
tags: [universal, testing, determinism]
works_with: all
severity: medium
one_liner: "Tests passing only in the author's timezone, locale, or shell setup"
---

# No Environment-Dependent Tests

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests that secretly assume a timezone, locale, OS, or env var and fail on every machine that differs.

**[Copy-paste ready version](../../install/no-environment-dependent-tests.md)** — just the instruction block, no explanation.

## The Problem

The test asserts `formatDate(ts)` returns `"06/10/2026, 2:30 PM"` — which it does, in the timezone and locale where it was written. Run it on a CI box pinned to UTC, or a colleague's machine in Berlin, and it's `"10.06.2026, 21:30"` and red. The assumption was never stated anywhere; it rode in through `toLocaleString()`'s defaults, `new Date(...)` interpreting a string in local time, a float formatted with a comma decimal under a different `LANG`, a filename test relying on case-insensitive macOS, sort order that changes with collation, or an `API_URL` env var that happened to exist in the author's shell.

AI assistants write these constantly because their verification loop runs in exactly one environment — whatever machine they're on — and an environment-dependent test is indistinguishable from a correct one there. The resulting failures are organizationally corrosive in a specific way: the test passes for its author and fails for someone else, which reads as "works on my machine" noise, gets rerun, argued about, and eventually contributes to the general belief that the suite cries wolf. The bug isn't in the code or really even in the test logic — it's in an assumption nobody wrote down.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Environment-Dependent Tests

A test must pass on any machine: any timezone, any locale, any OS, any shell. NEVER let a test's outcome depend on environment properties it doesn't explicitly control.

The core problem: environment assumptions enter silently — through locale-default formatting, local-time date parsing, OS path behavior, ambient env vars — and produce tests that pass for the author and fail for everyone else.

Rules:
- Timezone: never assert local-time renderings of a timestamp without pinning the zone. Construct dates explicitly in UTC (`Date.UTC(...)`, ISO strings with offsets, `datetime(..., tzinfo=timezone.utc)`); if the code under test formats in local time, set the zone for the test (`TZ=UTC` for the run, `timezone_machine`/library-level zone injection) and say which zone you pinned
- Locale: `toLocaleString`, `strftime` month names, decimal separators, and collation-based sort orders all vary by locale. Either pass the locale explicitly to the formatting call/assertion, or pin it for the test — never lean on the machine default
- Environment variables: a test that needs one sets it itself (via restoring mechanisms); a test that must not be affected by one clears it. Never depend on whatever the invoking shell exports
- Filesystem and OS: don't rely on case-insensitive filenames, path separator quirks, `/tmp` semantics, or tool availability (`which gsed`) that differ across platforms — build paths with the stdlib's path APIs and gate genuinely platform-specific tests with explicit, visible skips
- Network and ambient services: a unit test that touches a real host or assumes a port is free inherits every property of the machine around it; fake the boundary instead
- Review your own assertions for locale/zone fingerprints: slashes vs dots in dates, AM/PM, comma decimals, month names — each one is an assumption about the machine, written as an expectation about the code

**Red flags that you're about to violate this:**
- "The formatted output is 06/10/2026 here, so that's the expected value..."
- "CI also runs Linux, the path handling will be the same everywhere..."
- "That env var is always set in practice..."
- "toLocaleString output is stable enough to assert on..."
- "It passes on my run, the test is correct..."

---

## Why It Works

1. **It converts invisible defaults into explicit parameters.** Every variant of this failure is an unpinned default (zone, locale, env). The rule's structure — control it or don't depend on it — gives a uniform fix the AI can apply mechanically across all the categories.

2. **It teaches the fingerprints.** The AI can't audit for assumptions it can't see. Listing the tells — AM/PM, separator styles, month names, comma decimals — turns "check for environment dependence" into a pattern scan over its own expected values.

3. **It undermines single-environment verification.** "It passes on my run" is the exact evidence the AI uses, and it's structurally incapable of detecting this bug class. Saying so forces pinning rather than observation as the source of confidence.

## Origin

A reporting library's date tests were authored on a machine in US Eastern time and passed there for months — and failed instantly for a new contributor in Australia, then for CI after an infra migration to UTC runners. Triage burned most of a week across multiple people, including a stretch where the new contributor's environment was suspected of being "misconfigured" for being in the wrong hemisphere. The tests had been generated by an assistant that asserted whatever `toLocaleString()` printed on the original machine, encoding one office's wall clock as the definition of correct.
