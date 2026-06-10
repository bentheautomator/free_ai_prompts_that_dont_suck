---
title: Keep Dev Tools Out of Production Dependencies
slug: keep-dev-tools-out-of-production-dependencies
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "Stops putting test and build tooling in dependencies instead of devDependencies"
---

# Keep Dev Tools Out of Production Dependencies

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from declaring build, test, and lint tooling as production dependencies.

**[Copy-paste ready version](../../install/keep-dev-tools-out-of-production-dependencies.md)** — just the instruction block, no explanation.

## The Problem

`npm install jest` and `npm install --save-dev jest` differ by one flag, and AI assistants drop the flag constantly. The test framework, the linter, the TypeScript compiler, the bundler — tools that exist only to build and verify the code — land in `dependencies`, the section that means "this must be present wherever the app runs." Python projects get the mirror image: pytest and black written into the main `requirements.txt` that the production image installs.

The cost is paid at deploy time, forever. Production installs (`npm install --omit=dev`, multi-stage Docker builds, serverless bundling) are designed to skip dev tooling — but only if the manifest tells the truth about which is which. Misfiled, the test framework ships in every production image: bigger artifacts, slower cold starts, and a wider attack surface, since every misfiled package's CVEs are now production CVEs that page someone. Security teams triage vulnerability reports by "is it in prod?"; a manifest that files jest under production dependencies answers that question wrongly on every audit.

Assistants omit the flag because `npm install <pkg>` is the canonical command shape in training data, and because nothing fails: the tool works identically from either section on a dev machine. The distinction only matters in environments the assistant never sees.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It gives the filing decision a single mechanical test** — imported or invoked at production runtime? — replacing the importance-based intuition that misfiles TypeScript because it feels essential.
2. **It names the consumer of the distinction**: production install modes and security audits read these sections as facts about prod. The AI skips the flag because nothing visible depends on it; the rule supplies the invisible dependents.
3. **It blocks the overcorrection explicitly** — dev-flagging a runtime package is the rarer but louder failure (production crashes on a missing import), and a rule that caused it would get deleted.
4. **It pre-commits the command forms** (`-D`, `--group dev`), so following the rule is the same number of keystrokes as violating it.

## Origin

A serverless function whose actual job was resizing images carried a complete test framework, a linter, a bundler, and the TypeScript compiler in its production bundle — every one installed by an assistant without the dev flag across months of changes. Cold starts crept up as the artifact grew, and the team eventually noticed their image resizer's deployment package was 80% tooling that could never execute in production. The same quarter, a CVE in the bundled test framework triggered a production-incident process for code that existed in the artifact purely by filing error.
