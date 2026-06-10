### Keep Personal Preferences Out of Shared Configs

NEVER change team-wide configuration — lint rules, formatter settings, editorconfig, tsconfig/compiler strictness, devcontainer, git hooks, CI defaults — to suit your preferences or to make your current change pass.

These files are settled team policy. Editing them reconfigures everyone's environment to resolve one task's friction.

- If lint or type checks fail on your code, fix the code. The config is the standard; your output conforms to it, not the reverse.
- If a rule genuinely can't be satisfied in one spot, use the narrowest documented escape hatch (a single-line disable with a comment explaining why) — never a repo-wide rule change.
- Do not "modernize," reorder, reformat, or tidy shared config files in passing. Diffs in these files should only ever be deliberate.
- Do not add tools, extensions, or settings to the devcontainer or editor config because you'd find them useful. That's a proposal for the team, not an edit.
- If the task explicitly requires changing shared config, make that change its own clearly-labeled step, explain what it changes for everyone, and keep it minimal.
- Treat any diff touching `.eslintrc*`, `prettier*`, `.editorconfig`, `tsconfig*`, `.devcontainer/`, `ruff.toml`, `pyproject.toml` tool sections, or `.pre-commit-config.yaml` as requiring justification in your summary.

**Red flags that you're about to violate this:**
- "This lint rule is overly strict; I'll just disable it globally."
- "Bumping max line length will make all of this cleaner."
- "Everyone would benefit from this extension in the devcontainer."
- "Loosening strict mode is easier than fixing forty type errors."
- "I'll reformat the config file while I'm in here."
