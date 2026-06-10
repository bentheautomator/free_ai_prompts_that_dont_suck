---
title: Check Lint Config Before Styling Code
slug: check-lint-config-before-styling-code
category: context
tags: [universal, conventions, config]
works_with: all
severity: medium
one_liner: "AI styling code to its own taste instead of the repo's lint and format rules"
---

# Check Lint Config Before Styling Code

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from styling code by personal default when the repo's formatter and linter have already ruled.

**[Copy-paste ready version](../../install/check-lint-config-before-styling-code.md)** — just the instruction block, no explanation.

## The Problem

The repo has a `.prettierrc` saying single quotes, no semicolons, 100-character lines. The AI writes double quotes, semicolons everywhere, wrapped at 80 — its house style, applied with total confidence into a codebase that codified the opposite. Best case, a pre-commit hook reformats everything and only the diff noise suffers. Worse case, no hook exists locally, the PR fails CI on lint, and the round-trip to fix style burns time that one config read would have saved. Worst case, nothing enforces automatically and the codebase quietly accumulates two styles.

It goes beyond formatting. ESLint configs encode behavioral rules — no default exports, import ordering, no floating promises, naming patterns. Python repos pin ruff or flake8 rule sets with deliberate ignores. EditorConfig sets tabs vs spaces per file type. These files are the team's style constitution, written precisely so style stops being a discussion — and the AI re-opens the discussion every time it writes from its defaults. There's a destructive variant, too: the AI sees code that "violates" its own taste and reformats it mid-edit, producing diffs where one real change hides in three hundred cosmetic ones.

The constitution is short and sits at the repo root. Reading it takes less time than one lint-failure round-trip.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Lint Config Before Styling Code

ALWAYS write code to the repo's configured style, not your default style. The lint and formatter configs are the team's settled answer to every style question — your job is to comply with them, not to revisit them.

Off-style code costs a lint-failure round-trip when enforcement exists, and a creeping second style when it doesn't.

**Before writing or editing code:**
- Read the style constitution at the root: `.prettierrc*`, `.eslintrc*`/`eslint.config.*`, `.editorconfig`, `ruff.toml`/`setup.cfg`/`pyproject.toml` tool sections, `rustfmt.toml`, `.golangci.yml` — short files, big payoff
- Apply the specifics that diverge most often from defaults: quote style, semicolons, line length, tabs vs spaces, trailing commas, import ordering
- Treat lint rules as behavioral law, not just formatting: no-default-export, naming conventions, and promise-handling rules shape *what* you write, not just how it's spaced
- If the project exposes a format/lint command (`npm run lint`, `make fmt`, pre-commit config), run it on your changes before presenting them — let the tool be the authority
- Never reformat code you weren't asked to change: cosmetic churn buries the real diff and hijacks `git blame` — your edit should touch only the lines your change needs
- No config files at all? Match the style of the surrounding code instead of defaulting to your own

**Red flags that you're about to violate this:**
- "I'll use my usual formatting, it's standard..."
- "Semicolons are correct, whatever their config says..."
- "While I'm in this file, I'll tidy the formatting..."
- "The linter will sort it out later..."
- "Style configs are boilerplate, no need to read them..."
- Writing quotes, indentation, or line lengths you chose rather than looked up

---

## Why It Works

1. **It reframes configs as settled law.** "The team's settled answer to every style question" positions compliance as respecting a decision, not following a suggestion — which neutralizes the AI's instinct that its default is the correct one.

2. **It separates formatting rules from behavioral rules.** Treating lint as "just style" is how no-default-export and promise-handling violations slip through; naming the behavioral layer widens the check to where it bites.

3. **It delegates authority to the tool.** "Run the project's lint command and let it rule" converts an unwinnable taste argument into a mechanical pass/fail the AI can verify before presenting work.

4. **It bans drive-by reformatting.** The blast radius of style opinions is worst when applied to untouched code; the only-lines-your-change-needs rule keeps diffs reviewable and blame intact.

## Origin

A two-line bug fix arrived as a 400-line diff: the AI had "normalized" the entire file to its preferred style on the way through — quotes, semicolons, import order, the lot. The reviewer couldn't find the fix in the noise, requested a re-do, and the second attempt failed CI anyway because the AI's style contradicted the repo's lint config in four separate ways. Total elapsed time for a two-line fix: three days and two review cycles. The `.prettierrc` that would have prevented all of it was nine lines long.
