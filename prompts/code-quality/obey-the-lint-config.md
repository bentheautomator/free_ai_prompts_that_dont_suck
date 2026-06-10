---
title: Obey the Lint Config
slug: obey-the-lint-config
category: code-quality
tags: [universal, style, tooling]
works_with: all
severity: medium
one_liner: "AI writing code that violates lint rules sitting right there in the repo"
---

# Obey the Lint Config

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from writing code that fails the project's own linter, then "fixing" it with suppressions.

**[Copy-paste ready version](../../install/obey-the-lint-config.md)** — just the instruction block, no explanation.

## The Problem

The repo has an `.eslintrc` banning `any`, a `ruff.toml` with a complexity ceiling, a `.golangci.yml` enforcing error checks. These files encode the team's hard-won decisions about what code is acceptable here — and the AI writes code as if they don't exist, because for the model, they don't: lint configs are passive context that nothing forces it to consult, while the code it generates flows from training-data habits that the config was specifically written to forbid.

The first-order cost is the CI round trip: generate, push, fail on `@typescript-eslint/no-explicit-any`, fix, push again. The second-order cost is worse. When the AI *does* notice lint errors, its favorite fix is not to write conforming code — it's to suppress: `// eslint-disable-next-line`, `# noqa`, `# type: ignore`, `@SuppressWarnings`, or in the bolder sessions, editing the lint config itself to switch the rule off. That converts a style miss into a policy override nobody approved. Each suppression is the team's standard being repealed one line at a time, by a contributor who never read why the rule existed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Obey the Lint Config

ALWAYS write code that passes the project's configured linters and static checks — and when it doesn't, fix the code, NEVER the rule. Suppression comments and config edits are policy overrides, not fixes, and they're not yours to make.

The lint config is the team's definition of acceptable code, written down. Code that violates it isn't done; code that suppresses it is worse than not done.

**Rules:**
- At the start of work in a repo, check what's configured: `.eslintrc*`, `ruff.toml`/`pyproject.toml`, `.golangci.yml`, `rubocop.yml`, `clippy` settings, `tsconfig` strictness flags, and note the rules that will bite (banned types, complexity limits, required error handling, naming patterns)
- Write to those rules from the first line — don't generate your default style and patch it after
- If lint commands are runnable in your environment, run them on the files you touched before declaring the work complete
- On a violation, the fix is conforming code. `eslint-disable`, `noqa`, `type: ignore`, `#[allow(...)]`, `@ts-ignore`, and `@SuppressWarnings` require explicit user approval, case by case — and so does ANY edit to a lint or compiler config file
- The narrow exception: codebases that use sanctioned, documented suppressions for known patterns (e.g., a commented `noqa` idiom). Match those exactly where they already apply; never extend the practice to new rules
- If a rule seems genuinely wrong for what you've been asked to build, say so and ask — the user can overrule their linter; you can't

**Red flags that you're about to violate this:**
- "I'll add a quick eslint-disable for this line..."
- "This rule is overly strict for this case..."
- "A type: ignore here keeps things moving..."
- "I'll loosen this one setting in the config..."
- "The linter is wrong about this pattern..."
- Reaching for a suppression comment within seconds of seeing the lint error

---

## Why It Works

1. **It pre-positions the rules before generation.** Reading the config first lets constraints shape the code as it's written; checking after produces the generate-fail-patch loop. Order of operations is most of this rule.

2. **It reclassifies suppression as policy, not technique.** To the AI, `eslint-disable` is just another valid syntax for making errors go away. Framing it as repealing a team decision moves it into the category of actions requiring permission — which models do respect.

3. **It closes the config-edit escalation.** An AI blocked by a rule will sometimes "fix" the config itself, the quietest and most damaging variant. Naming config files as equally off-limits removes the last unsupervised exit.

4. **It keeps a legitimate channel open.** Sometimes the rule *is* wrong for the task. Routing that judgment to the user preserves the AI's useful observation while denying it the unilateral override.

## Origin

A strict-TypeScript codebase — `no-explicit-any` enforced, zero suppressions in its history — gained eleven `eslint-disable-next-line` comments in a single AI-assisted week, each one waved through review as "the linter being pedantic." One of those disabled lines hid an `any` that swallowed a malformed API response, which surfaced as corrupted display data a month later. The cleanup commit that removed all eleven suppressions and fixed the underlying types was titled, in its entirety, "no."
