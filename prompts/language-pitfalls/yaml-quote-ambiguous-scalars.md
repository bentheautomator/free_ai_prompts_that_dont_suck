---
title: YAML Quote Ambiguous Scalars
slug: yaml-quote-ambiguous-scalars
category: language-pitfalls
tags: [universal, yaml]
works_with: all
severity: high
one_liner: "Stops YAML turning no into false, 1.10 into 1.1, and 0755 into 493"
---

# YAML Quote Ambiguous Scalars

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents unquoted YAML scalars being type-coerced: country code `NO` becomes `false`, version `1.10` becomes the float `1.1`, and your config lies to you.

**[Copy-paste ready version](../../install/yaml-quote-ambiguous-scalars.md)** — just the instruction block, no explanation.

## The Problem

YAML guesses the type of every unquoted scalar, and it guesses with enthusiasm. The famous casualty is Norway: `country: NO` parses as boolean `false` under YAML 1.1 (along with `yes`, `no`, `on`, `off`, `y`, `n`, in assorted capitalizations — many parsers still implement this). Version numbers are next: `version: 1.10` is the float `1.1`, indistinguishable from `1.1` and very distinguishable from what you meant. Then `mode: 0755` parses as octal 493, `serial: 1e2` becomes 100.0, a Git SHA that happens to be all digits becomes an integer, and an unquoted `time: 12:30` is, in YAML 1.1, sexagesimal for 750. A bare `value:` with nothing after it is `null`, not empty string.

None of this errors. The config loads, the wrong value flows into the application, and the symptom appears wherever that value is consumed — a "false" country code, an image tag that doesn't exist because `3.10` was requested as `3.1`.

Assistants generate unquoted YAML because most YAML in training data is unquoted and most values are unambiguous, so the habit is unquoted-by-default. Models also "clean up" existing configs by stripping quotes that look redundant — which is precisely how a previously safe `"NO"` regresses.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### YAML Quote Ambiguous Scalars

ALWAYS quote YAML values that are strings but look like another type. YAML type-guesses unquoted scalars, and several legitimate strings parse as booleans, numbers, or null with no warning.

- Quote anything matching these shapes when a string is intended: `yes/no/on/off/y/n/true/false` in any case (`country: "NO"`), version-like numbers (`version: "1.10"` — unquoted it's the float `1.1`), leading-zero values (`mode: "0755"`, zip codes like `"02134"`), scientific-notation lookalikes (`"1e5"`), colon-separated times (`"12:30"`), and `null`/`~`.
- All-digit identifiers (phone numbers, account ids, some Git SHAs) must be quoted or they become integers — possibly losing leading zeros or precision.
- An empty value (`key:`) is `null`, not `""`. Write `key: ""` for empty string.
- Booleans and numbers that are MEANT to be booleans and numbers stay unquoted: `enabled: true`, `replicas: 3`. The rule is about strings in disguise.
- Never strip quotes from existing YAML as cleanup. A quote in a config file is load-bearing until proven decorative.
- When generating YAML programmatically, use a real YAML library, not string templating — templating an unquoted user-supplied value into YAML is both a coercion bug and an injection bug.
- Be alert in the usual blast zones: docker-compose/CI image tags (`image: postgres:9.6` is fine; `tag: 9.60` is the float trap), Kubernetes env vars (all values must be strings — unquoted `PORT: 8080` fails or coerces depending on tooling), Ansible/Helm values files, and country/language code lists.

**Red flags that you're about to violate this:**

- "Quotes around simple values are unnecessary noise in YAML."
- "I'll normalize this config by removing redundant quoting."
- "It's a version number, YAML will keep it as written."
- "The parser we use is YAML 1.2, the boolean thing is fixed." (Is every consumer of this file?)
- "Env var values are obviously strings, no need to quote 8080."

---

## Why It Works

1. **It enumerates the disguises.** "Quote ambiguous values" fails because the model's ambiguity detector is the thing that's broken; a concrete list of shapes (NO, 1.10, 0755, 12:30, 1e5) substitutes recall for judgment.
2. **It outlaws quote-stripping cleanup.** Half these regressions come from "tidying" working configs; declaring existing quotes load-bearing blocks the edit that causes them.
3. **It keeps real booleans unquoted.** Without the carve-out, the model over-rotates to quoting `true` and `3`, breaking typed consumers and getting the rule reverted.
4. **It names the blast zones.** Image tags, env vars, and country codes are where this bug actually lands in repos; location-specific warnings fire when generic ones don't.

## Origin

A localization rollout added supported countries to a values file: `- SE`, `- DK`, `- NO`, `- FI`. Three countries launched; Norway's entry parsed as boolean `false`, failed a string filter downstream, and simply vanished from the supported list. No error, no crash — just a market that didn't exist as far as the feature flag system was concerned, discovered when the regional team asked why their launch announcement pointed at a 404.
