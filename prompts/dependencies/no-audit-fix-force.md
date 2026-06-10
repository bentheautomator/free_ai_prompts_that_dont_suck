---
title: No npm audit fix --force
slug: no-audit-fix-force
category: dependencies
tags: [universal, dependencies, versions]
works_with: all
severity: high
one_liner: "Stops audit fix --force from installing breaking majors to clear warnings"
---

# No npm audit fix --force

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from clearing audit warnings with a command that is documented to install breaking changes.

**[Copy-paste ready version](../../install/no-audit-fix-force.md)** — just the instruction block, no explanation.

## The Problem

The install output says `12 vulnerabilities (3 moderate, 9 high)`, npm helpfully suggests `npm audit fix --force`, and the AI assistant — primed to clear warnings and offered a command that does it — runs the suggestion. npm's own output describes what the flag does in plain text: it installs breaking changes, jumping packages across major versions and even downgrading them, whatever makes the advisory database happy. The assistant has just authorized semver-major churn across the dependency tree to silence a warning count, usually as a side quest inside an unrelated task.

The aftermath is a classic shape: webpack jumps a major and the build config stops parsing; a framework plugin moves to a version that targets a different framework major than the one installed; something gets *downgraded* into an API the code doesn't use anymore. And the prize for accepting all this breakage is frequently nothing — many flagged advisories sit in dev-only tooling or unreachable code paths, where "high severity" on the label doesn't mean high risk in context. Meanwhile plain `npm audit fix` (no flag) already handles everything fixable within semver-compatible ranges, safely.

Assistants run the forced version because the tool itself suggests it, the warning count going to zero reads as success, and the words "breaking changes" in the explanatory text carry no weight against a green outcome.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No npm audit fix --force

NEVER run `npm audit fix --force`. The flag's documented behavior is installing breaking changes — major-version jumps and downgrades across the tree — in exchange for a lower warning count. That trade is never yours to make unilaterally.

- Plain `npm audit fix` (no `--force`) is acceptable: it only applies updates within existing semver ranges. Run it, then diff the lockfile and confirm the changes are the expected patches/minors.
- For advisories that remain, triage instead of forcing: `npm audit` shows which dependency path each advisory enters through. A vulnerability in a dev-only build tool that never sees production input is a different priority than one in request parsing — say which kind each is.
- Fix stubborn advisories surgically: upgrade the specific direct dependency that pulls in the vulnerable version, or use a targeted `overrides` entry pinning the one transitive package to a patched version. One advisory, one deliberate change.
- If a fix genuinely requires a major-version migration, present that to the user as a migration — with the breaking changes named — not as a forced flag inside a cleanup commit.
- Audit warnings in install output are not your task unless the user made them your task. Report them; don't reflexively eliminate them, and never at the cost of unreviewed major bumps.

**Red flags that you're about to violate this:**
- "npm itself is suggesting the --force command."
- "Getting vulnerabilities to zero is obviously the right outcome."
- "The breaking changes warning is boilerplate; it'll probably be fine."
- "I'll just run it and see if the tests still pass."
- "Security fixes justify whatever version changes they require."

---

## Why It Works

1. **It quotes the flag's own documentation back at the decision** — "installs breaking changes" is npm's description, not the rule's characterization — which removes the ambiguity the AI exploits when a tool suggests its own escalation.
2. **It separates the safe command from the forced one.** Most of the AI's legitimate goal is achievable with plain `audit fix`; giving it that keeps the rule from blocking the productive 80%.
3. **It replaces warning-count-zero with triage as the success metric**, attacking the actual driver — the AI optimizes for clean output, and advisory counts are the cleanest-looking number to zero out.
4. **It provides the surgical alternative** (path-targeted upgrades, scoped `overrides`), so even the genuinely-needs-fixing advisory has a route that doesn't involve tree-wide forced churn.

## Origin

Asked to fix one failing snapshot test, an assistant noticed nine high-severity advisories in the install output and ran the suggested `npm audit fix --force` "while at it." The command moved fourteen packages, including the bundler across two majors and a framework adapter onto a line meant for the framework's next release. The snapshot test now passed — alongside a build that wouldn't compile. Reverting took an afternoon; the kicker from the postmortem was that eight of the nine advisories were in dev-only tooling, and the ninth had a one-line `overrides` fix.
