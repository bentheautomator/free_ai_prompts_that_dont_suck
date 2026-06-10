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
