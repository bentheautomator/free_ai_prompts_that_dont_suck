### Never Leave the Shared Build Broken

NEVER finish a task leaving the shared build, test suite, or dev environment broken. "My feature works" is not done; "the team's world still works" is done.

Everyone on the team pays for a broken build, and the cheapest moment to fix it is right now, while you have the context.

- Before declaring a task complete, run the project's standard verification — the full build, the lint command, the test suite the team actually uses — not just the tests for your change.
- If you changed anything in the dev environment (Dockerfile, docker-compose, devcontainer, Makefile, setup scripts, seed data), verify the environment still comes up from scratch, or say plainly that you couldn't verify it.
- If you discover the build is already broken by your change, fixing it is now your top priority — ahead of the next feature, ahead of cleanup, ahead of everything.
- If you cannot fix the breakage, say so loudly: what's broken, what caused it, and the revert that restores green. Never bury a known break in a success summary.
- Renamed or deleted scripts, make targets, and npm scripts count: search for what calls them (CI configs, docs, other scripts) before assuming nothing does.

**Red flags that you're about to violate this:**
- "My tests pass; the full build is CI's job to check."
- "That compile error is in a module I barely touched, probably pre-existing."
- "I'll mention the broken script in passing and keep going."
- "Someone will notice and fix the dev container."
- "The build failure looks flaky, moving on."
