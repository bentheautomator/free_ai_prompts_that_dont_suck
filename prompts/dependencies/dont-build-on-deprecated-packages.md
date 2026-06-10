---
title: Don't Build on Deprecated Packages
slug: dont-build-on-deprecated-packages
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "Stops new code built on request, moment, and other marked-dead packages"
---

# Don't Build on Deprecated Packages

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from choosing a formally deprecated package for new functionality because training data still loves it.

**[Copy-paste ready version](../../install/dont-build-on-deprecated-packages.md)** — just the instruction block, no explanation.

## The Problem

Some of the most-installed packages in history are formally deprecated, and AI assistants keep choosing them for new code. `request` was deprecated in 2020 and still gets written into new Node services. `moment` is in maintenance mode with its own docs steering people to alternatives, and assistants still reach for it for greenfield date handling. The training data contains a decade of tutorials built on these packages; the deprecation notice is one line that came later.

Deprecated is different from merely unmaintained: the maintainers have explicitly told you to stop. There will be no new features, often no fixes, and the ecosystem is actively migrating away — which means every line of new code written against the package is migration debt created knowingly. The package manager even says so out loud: npm prints `deprecated` warnings during install, in yellow, and assistants scroll past them to confirm the install "succeeded."

The failure isn't ignorance of the replacement — ask an assistant directly and it knows `request` is dead and `fetch` is built in now. The failure is that under task pressure, recall frequency beats recency, and nothing in the loop forces the deprecation signal to be read.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Build on Deprecated Packages

NEVER choose a deprecated package for new code. Deprecated means the maintainers have formally told users to leave; building new functionality on it is creating migration debt on purpose.

- Read install output. If the package manager prints a `deprecated` warning for a package you just added, that's a decision point, not noise: identify the recommended replacement (usually named in the warning or the README) and use it instead.
- Before reaching for a package you "know" is standard, consider its era. If your knowledge of it comes from older tutorials, verify its current status on the registry page — the famous packages most likely to be deprecated are exactly the ones training data over-represents.
- Know the headline cases in JS: `request` (deprecated; use built-in `fetch`, `undici`, or `axios`), `moment` (maintenance mode; use `date-fns`, `dayjs`, or the `Temporal` API where available). Equivalent graveyards exist in every ecosystem.
- An existing deprecated dependency already in the project is a different situation: don't rip it out unasked, but don't expand its footprint either. Write new code against the modern alternative, and mention the migration opportunity.
- Deprecation warnings for transitive dependencies you didn't choose are informational — note them if asked about install output, but they don't block your task.

**Red flags that you're about to violate this:**
- "This package is the classic choice for this; millions of projects use it."
- "The deprecation warning is just noise; the install worked."
- "It's deprecated but it still functions, so it's fine for now."
- "The codebase already uses it somewhere, so adding more is consistent."
- "Switching to the replacement would mean learning a different API."

---

## Why It Works

1. **It separates deprecated from old.** The AI lumps both into "still works"; the rule defines deprecated as an explicit instruction from the maintainers, which is a category the AI respects.
2. **It makes install output a required read.** The yellow warning is the ecosystem literally announcing the problem at the exact moment of the mistake — the rule just forces the AI to stop scrolling past it.
3. **It pre-loads the highest-frequency cases** (`request`, `moment`) so the most statistically likely failures are blocked by name, not just by principle.
4. **It draws the expand-versus-remove line** for existing usage, preventing both the overcorrection (unsolicited migration PRs) and the slow failure (deprecated package metastasizing through new code).

## Origin

A new internal API client, written entirely by an assistant in 2024, was built on a HTTP library that had been formally deprecated four years earlier — the install log said so, twice. Eighteen months later a TLS-handling bug surfaced that the dead library would never fix, and the "quick client" needed a full rewrite. The replacement library the team migrated to was the same one the deprecation notice had recommended in the install output nobody read.
