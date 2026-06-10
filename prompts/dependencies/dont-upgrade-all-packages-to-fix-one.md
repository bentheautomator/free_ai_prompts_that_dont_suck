---
title: Don't Upgrade All Packages to Fix One
slug: dont-upgrade-all-packages-to-fix-one
category: dependencies
tags: [universal, dependencies, versions]
works_with: all
severity: high
one_liner: "Stops blanket npm update runs that bump fifty packages to fix one problem"
---

# Don't Upgrade All Packages to Fix One

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from responding to one broken or outdated package by upgrading the entire dependency tree.

**[Copy-paste ready version](../../install/dont-upgrade-all-packages-to-fix-one.md)** — just the instruction block, no explanation.

## The Problem

One package needs a bump — a bug got fixed upstream, or a version conflict needs untangling — and the assistant's chosen tool is a sledgehammer: `npm update`, `pip install -U -r requirements.txt`, `bundle update` with no arguments, or worse, running `npm-check-updates -u` and accepting every suggestion. Fifty packages move at once. The one that mattered moved too, so the task is "done."

A whole-tree upgrade is fifty simultaneous changes with one test run to validate all of them. When something breaks — and across fifty packages, something does — there's no way to know which bump caused it without bisecting the whole set. The PR becomes unreviewable: the intentional fix is buried in pages of version churn, and the reviewer either rubber-stamps it or rejects the genuinely needed fix along with the noise. Either outcome is bad.

Assistants do this because blanket commands are easier than targeted ones — no need to identify exactly which package and which version, just update everything and let resolution sort it out. There's also a learned association between "dependency problem" and "make everything newest," as if freshness were a repair strategy rather than fifty separate gambles taken at once.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Upgrade All Packages to Fix One

NEVER run a blanket upgrade (`npm update`, `bundle update` with no package, `pip install -U` across a requirements file, `npm-check-updates -u`) to solve a problem with one package. Upgrade the package that has the problem, and nothing else.

- Identify the specific package and target version first, then move only it: `npm install pkg@5.1.2`, `bundle update <gem>`, `poetry update <pkg>`, `cargo update -p <crate>`.
- After the targeted upgrade, diff the lockfile. Some transitive movement is normal; if the diff shows dozens of unrelated top-level packages moving, you used the wrong command — reset and redo it narrowly.
- One PR, one intention. A bug fix and a dependency refresh are different changes with different risk profiles and different reviewers' attention. Never combine them.
- If the user explicitly asks to "update all dependencies," structure it for survivability: patches and minors in one pass, each major as its own commit with its changelog read, tests run between stages. Flag that this is inherently risky work, not housekeeping.
- "While I'm in here, these are outdated too" is not a reason. Outdatedness alone breaks nothing; an unreviewed mass upgrade regularly does.

**Red flags that you're about to violate this:**
- "Updating everything at once gets it over with."
- "Newer versions are generally better, so this is strictly an improvement."
- "The other packages are old anyway; this is a good opportunity."
- "npm update is the standard command for fixing version issues."
- "One test run will tell us if any of the fifty bumps broke something."

---

## Why It Works

1. **It severs the false link between freshness and repair.** The AI treats "make everything newest" as a fix-shaped action; the rule reframes it as fifty unrelated gambles bundled with one fix.
2. **It makes the lockfile diff the verdict.** "Dozens of unrelated packages moved" is an objective, checkable signal that the command was too broad — no judgment required.
3. **It preserves bisectability as an explicit value.** One-change-per-commit isn't ceremony; it's what makes the inevitable breakage findable, and saying so gives the AI the reason, not just the rule.
4. **It handles the legitimate request** (a deliberate full refresh) with a staged procedure, so the AI doesn't read the rule as "refuse upgrades."

## Origin

A flaky date-formatting bug needed a one-package patch bump. The assistant ran a check-updates tool, accepted all suggestions, and shipped a PR moving 61 packages including four majors. Tests passed; the staging environment then broke in three unrelated places — auth, file uploads, and a PDF export. Bisecting which of the four majors caused which breakage consumed two days. The original date bug fix, isolated, would have been a five-minute review.
