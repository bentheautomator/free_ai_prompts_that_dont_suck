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
