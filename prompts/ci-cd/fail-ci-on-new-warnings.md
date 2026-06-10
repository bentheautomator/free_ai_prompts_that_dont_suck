---
title: Fail CI on New Warnings
slug: fail-ci-on-new-warnings
category: ci-cd
tags: [universal, ci]
works_with: all
severity: medium
one_liner: "Stops the AI from letting warnings scroll past in CI until one becomes an outage"
---

# Fail CI on New Warnings

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from configuring pipelines where warnings print, scroll, and accumulate without ever failing anything.

**[Copy-paste ready version](../../install/fail-ci-on-new-warnings.md)** — just the instruction block, no explanation.

## The Problem

A warning in CI that doesn't fail the build isn't a warning; it's a log line. Nobody reads passing-job logs. So deprecation notices, compiler warnings, peer-dependency mismatches, and "this config option will be removed in the next major" messages print into the void at a rate of dozens per run, and the count only ever goes up — because the one force that could hold it at zero, a red build, was never wired to it. By the time a warning matters (the deprecated API is now removed, the implicit-any was hiding a real type error), it's buried in 400 lines of other warnings everyone has been trained to scroll past.

The accumulation has a ratchet structure: at zero warnings, keeping zero is cheap; at 50, getting back to zero is a project nobody schedules. The only affordable moment to enforce a warning is when it's new. Pipelines that don't fail on new warnings choose, structurally, to deal with every warning later, at maximum price.

AI assistants make this worse in both directions. Generating pipelines, they wire up `build` and `test` with default settings, where warnings are non-fatal — so the ratchet starts on day one. And when an existing strict pipeline fails on a warning the assistant's own code introduced, the tempting diff is removing `-W error` or `--max-warnings 0` rather than fixing the warning, since the flag change is one line and the warning might take ten.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Fail CI on New Warnings

Pipelines must treat new warnings as failures. ALWAYS enable warnings-as-errors in CI for the toolchains that support it, and NEVER weaken an existing warnings-as-errors setting to get a build passing.

A warning that can't fail the build will be read by no one and fixed by no one, until the day it stops being a warning.

- Wire it at the tool level: `eslint --max-warnings 0`, `tsc` with strict options, `-Werror` for compilers, `python -W error` or `filterwarnings = error` in pytest config, `RUSTFLAGS="-D warnings"`, `mvn -Werror`. Prefer the tool's config file over a CI-only flag so local runs fail the same way.
- When your change introduces a warning, the fix is in the code: migrate off the deprecated call, add the type, address the lint. Suppressing it (`# noqa`, `@SuppressWarnings`, `eslint-disable`) requires a justification comment at the suppression site explaining why the warning is wrong *here* — not why it's inconvenient.
- For an existing codebase with a warning backlog, don't flip everything to fatal in one PR (that just gets reverted). Ratchet instead: fail on warnings in changed files, snapshot the current count and fail on increases, or enable per-rule as each category reaches zero. The invariant to enforce is "no new warnings," immediately.
- Never respond to a warnings-as-errors failure by removing or loosening the flag, raising `--max-warnings`, or adding the warning's category to an ignore list. That converts a build failure into a permanent blind spot.
- Treat deprecation warnings from dependencies as scheduled future breakage: if you can't fix one now, surface it to the user as a tracked item rather than silencing it.

**Red flags that you're about to violate this:**

- "It's only a warning; the build still works."
- "I'll bump max-warnings from 0 to 3 since my change adds 3."
- "This deprecation won't bite until the next major version, which is ages away."
- "The strict flag is what's broken here, not my code."
- "Everyone ignores these warnings anyway, so failing on them is theater."

---

## Why It Works

1. **It connects warnings to the only channel that gets read.** CI has exactly one reliable signal — red — and information not routed through it is effectively unpublished.
2. **It prices warnings at their cheapest moment.** A new warning costs minutes in the PR that created it and days once it has company; failing immediately is the only point on the curve where enforcement is affordable.
3. **The ratchet option makes strictness adoptable**, removing the "we have 400 warnings, so fatal warnings are impossible" objection that otherwise justifies doing nothing forever.
4. **It distinguishes suppression-with-reasoning from suppression-as-evasion.** Justified, sited suppressions keep the mechanism honest; the rule bans only the silent kind, which is the kind assistants produce under deadline pressure.

## Origin

A service's logs had shown a driver deprecation warning on every CI run for nine months — the connection-string format was going away. The pipeline was green throughout, so it appeared in no one's workflow, and the warning scrolled by roughly 1,400 times. The driver's next major release landed via an automated dependency bump, the old format stopped parsing, and the service failed to boot in production with an error message the team had technically been sent every day since the previous summer.
