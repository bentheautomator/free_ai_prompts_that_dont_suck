### Keep Dev Tools Out of Production Dependencies

ALWAYS file dependencies by where they're needed at runtime, not just install them. Anything used only to build, test, lint, or format the code goes in `devDependencies` (or the dev/test extra in Python) — `dependencies` is a claim that production cannot run without this package.

- Dev-flag the obvious tooling every time: test frameworks (jest, vitest, pytest), linters and formatters (eslint, prettier, ruff, black), type checkers and compilers (typescript, mypy), bundlers and build plugins (webpack, vite, esbuild), and type stubs (`@types/*`). Command forms: `npm install -D`, `pnpm add -D`, `poetry add --group dev`, or the `[dev]` extra in pyproject.
- The test is "does the code import or invoke this at production runtime?" — not "is it important." TypeScript is critical to the project and still a devDependency, because production runs the compiled output.
- Genuine runtime packages (the web framework, the database driver, the HTTP client your code imports) belong in `dependencies` — don't overcorrect and dev-flag something the server imports, which breaks production installs in the opposite direction.
- Edge cases follow the same test: a build tool invoked by a production start script is a runtime need; a CLI used only in CI is not. When a package serves both, `dependencies` wins.
- When you notice an obviously misfiled package while editing the manifest, mention it. Don't silently re-shelve someone else's entries, but don't leave the observation unsaid.

**Red flags that you're about to violate this:**
- "npm install jest — done."
- "The section doesn't really matter; it all ends up in node_modules."
- "This tool is essential to the project, so it's a real dependency."
- "I'll sort out dependency sections later; installing is the task."
- "requirements.txt is the place Python dependencies go." (all of them?)
