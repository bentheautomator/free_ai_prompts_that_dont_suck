---
title: No Unrequested Dev Tooling
slug: no-unrequested-dev-tooling
category: scope
tags: [universal, scope]
works_with: all
severity: medium
one_liner: "AI adding linters, CI configs, and pre-commit hooks unprompted"
---

# No Unrequested Dev Tooling

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from installing linters, formatters, CI workflows, and git hooks the team never asked for.

**[Copy-paste ready version](../../install/no-unrequested-dev-tooling.md)** — just the instruction block, no explanation.

## The Problem

Tucked into the diff for an ordinary feature: a `.pre-commit-config.yaml`, a new linter config with sixty default rules, an `.editorconfig`, and a GitHub Actions workflow that runs it all on every push. The AI noticed the project "lacked" tooling and corrected the deficiency on its way through. Nobody asked. Now every contributor's next push gets blocked by a hook they didn't install, failing rules nobody chose.

Dev tooling is team governance in file form. A linter config is a policy about what code is acceptable; a CI workflow is a gate everyone must pass; a pre-commit hook modifies every teammate's local workflow. These are decisions teams make through discussion precisely because they bind everyone — and an AI smuggling them in via an unrelated PR is unilateral legislation. The practical fallout is immediate: the new linter flags hundreds of pre-existing violations (so either the diff balloons with "fixes" or CI is born red), the hook surprises whoever pushes next, and the workflow file starts consuming CI minutes on an untuned matrix.

A missing linter in a repo is not an oversight the AI should patch. It's a fact about the team's current choices, changeable by the team.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Unrequested Dev Tooling

NEVER add or modify development tooling (linters, formatters, git hooks, CI/CD workflows, editor configs) unless tooling is the task.

The core problem: tooling files are team policy that binds every contributor's workflow, and introducing them inside an unrelated change is a governance decision made unilaterally and reviewed accidentally.

- No new linter, formatter, or type-checker configs, and no rule changes to existing ones, while doing feature or fix work
- No git hooks or hook-manager configs; these execute on teammates' machines and block their commits
- No CI/CD additions or edits (workflows, pipelines) in passing; a CI change is a gate change for the whole team
- No editor or IDE settings committed to the repo (.editorconfig, .vscode/, etc.) on your own initiative
- Satisfy existing tooling rather than adjusting it: if the project's linter rejects your code, fix the code; never suppress, reconfigure, or version-bump the tool to make your diff pass (if a rule seems genuinely wrong, say so and let the team change it)
- Think tooling would help? Recommend, with reasons, in one or two sentences: "This repo has no formatter config; want one set up as its own change?" Adoption is the team's call

**Red flags that you're about to violate this:**
- "This project really should have a linter, I'll set one up..."
- "I'll add a pre-commit hook so this class of bug can't recur..."
- "A CI workflow for tests is an obvious missing piece..."
- "I'll just disable this one lint rule, it's too strict anyway..."
- "Standard tooling is table stakes, they'll appreciate it..."

---

## Why It Works

1. **It names tooling as governance.** The AI files configs under "project files like any other"; reclassifying them as policy binding every contributor explains why they need consent, not initiative.

2. **It blocks the suppress-to-pass move.** The most common micro-version of this creep is loosening a rule to green a diff; "fix the code, never the tool" closes it while leaving an honest channel for genuinely bad rules.

3. **It surfaces the blast radius.** Hooks run on other people's machines and CI gates everyone's merges; stating this makes "I'll just add it" visibly a decision about other people.

4. **It converts the instinct into a recommendation.** The AI's diagnosis (missing tooling) is often correct; the one-sentence proposal preserves the insight and hands the adoption decision to those it binds.

## Origin

A feature PR arrived carrying a surprise pre-commit config and a strict linter setup. It was approved on the strength of the feature, and the next morning four engineers found their commits blocked by hooks demanding changes to files they hadn't touched, including one engineer mid-hotfix. The hotfix went out twenty minutes late with `--no-verify`, the tooling was reverted by lunch, and the team then adopted nearly identical tooling two weeks later — through a discussion, a gradual-rollout config, and a PR that said what it was.
