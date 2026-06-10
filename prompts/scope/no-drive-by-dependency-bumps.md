---
title: No Drive-By Dependency Bumps
slug: no-drive-by-dependency-bumps
category: scope
tags: [universal, scope, focus]
works_with: all
severity: high
one_liner: "AI bumping dependency versions in the middle of an unrelated task"
---

# No Drive-By Dependency Bumps

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from upgrading packages, lockfiles, and toolchain versions as a side quest during unrelated work.

**[Copy-paste ready version](../../install/no-drive-by-dependency-bumps.md)** — just the instruction block, no explanation.

## The Problem

You asked for a bug fix. The diff includes the fix — and a modified lockfile, three version ranges widened in the manifest, and sometimes a bumped language or runtime version in CI config, because the AI noticed the project was "behind" and updated it on the way through. A 5-line fix now carries a 2,000-line lockfile diff that no human will read.

The AI does this because outdated versions pattern-match to neglect, and because running install commands during its work can rewrite lockfiles as a side effect it then commits without comment. But dependency versions are pinned for reasons that live outside the code: a known regression in a newer minor, a platform that lags, a compliance process that reviews upgrades, a transitive pin that took someone a day to get right. A casual bump bypasses all of it, and the lockfile diff is the perfect camouflage — reviewers scroll past machine-generated noise, which means a drive-by upgrade is effectively an unreviewed production change to every line of vendored behavior.

When the upgraded package breaks something next week, the breakage will be attributed to a commit titled "fix date parsing," which is where debugging goes to die.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Drive-By Dependency Bumps

NEVER change dependency versions, lockfiles, or toolchain pins unless upgrading is the task. Versions are pinned decisions, not staleness to clean up.

The core problem: a version bump changes every behavior the dependency provides, ships inside an unreadable lockfile diff, and bypasses whatever reason the pin existed, all under the title of an unrelated change.

- Do not edit version specifiers in manifests (package.json, requirements.txt, Cargo.toml, go.mod, etc.) during other work
- If a command you run regenerates a lockfile incidentally, restore it before delivering unless the task required a dependency change
- Do not bump language, runtime, or tool versions in CI configs, Dockerfiles, or version files (.nvmrc, .python-version, etc.) in passing
- Do not "fix" a problem by upgrading a package when a code-level fix inside the current versions exists; if upgrade genuinely is the fix, say so and ask first
- Adding a brand-new dependency is a separate decision with its own rules; this rule is about not touching the versions of what exists
- If you notice a security advisory or a badly outdated pin, report it in one or two sentences; the upgrade gets its own task, its own diff, and its own test run

**Red flags that you're about to violate this:**
- "This package is several versions behind, I'll update it while I'm here..."
- "The lockfile changed when I installed, I'll just commit it..."
- "Newer versions probably fix this bug, easier than patching..."
- "I'll bump the minor version, it's semver-safe..."
- "Updating dependencies is basic hygiene..."

---

## Why It Works

1. **It recasts pins as decisions.** The AI reads old versions as neglect; stating that pins encode invisible constraints (regressions, platforms, compliance) gives it a reason to believe the current version is intentional.

2. **It handles the accidental lockfile path.** Much of this creep isn't a choice but a side effect of running installers; requiring restoration before delivery catches the case where the AI never "decided" anything.

3. **It blocks upgrade-as-fix laziness.** "A newer version probably fixes it" trades a visible code change for an invisible everything-change; requiring the ask makes that trade explicit.

4. **It rejects the semver excuse.** "Minor bumps are safe" is a contract claim, not a test result; naming it as a red flag stops it from standing in for verification.

## Origin

While adding a CSV export, an assistant ran the package installer, picked up a minor bump of an HTTP client, and committed the lockfile. The new minor changed default timeout behavior. Two weeks later, a downstream service slowdown began triggering cascading request failures that the old infinite-default had absorbed. The incident review traced it to a commit titled "add CSV export," and the engineer on call spent most of a night proving the CSV code was innocent.
