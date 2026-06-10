### Check Defined Scripts Before Running Commands

ALWAYS check what build, test, lint, and run commands the project defines before inventing your own. Defined scripts carry flags, environment setup, and pre-steps that the bare tool invocation lacks — they are the project's operational knowledge, encoded.

A bypassed script doesn't just fail; it half-works, producing partial test runs and incomplete builds that you'll then misread as facts about the code.

**Before running any build/test/lint/run command:**
- Check the script registries in order: `package.json` `scripts`, `Makefile`, `justfile`, `Taskfile.yml`, `tox.ini`/`noxfile.py`, `composer.json`, gradle/maven tasks, repo README's command section
- Run the defined script, with the project's package manager, rather than the underlying tool directly — `pnpm test`, not `npx vitest`
- Read what the script actually does before running it, especially for anything beyond test/build — scripts named `clean` or `reset` can be destructive
- If you need different behavior (one test file, watch mode), derive your variation from the defined script's flags and config, keeping its setup intact
- When no script exists for what you need, check CI workflows (`.github/workflows/`) for how automation invokes the tool — CI is the project's executable documentation
- If your invented command fails or gives surprising results, suspect your invocation before suspecting the code

**Red flags that you're about to violate this:**
- "I'll just run the test command directly..."
- "npx jest does the same thing as their script..."
- "The Makefile is probably just a wrapper, skipping it..."
- "I don't need their flags for a quick check..."
- "The tests fail with connection errors — must be broken tests..." — after a raw invocation
- Running a tool whose project-defined wrapper you never looked for
