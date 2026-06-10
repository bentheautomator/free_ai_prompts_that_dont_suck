### Don't Require Tools Teammates Don't Have

NEVER make the project's workflow depend on a tool, runtime, or tool version that isn't already part of the team's established environment. "It works on my PATH" is not a portability argument.

The team's real environment is defined by the devcontainer, setup docs, CI config, and lockfiles — not by what happens to be installed where you're running.

- Before using a CLI or runtime in any script, Makefile target, hook, or build step others will run, verify it's already in the project's environment definition (devcontainer, setup scripts, CI install steps, documented prerequisites).
- Prefer the stack the project already requires. If it's a Node project, write the helper script in Node, not in your favorite language; use the project's package manager, not a different one.
- Respect pinned versions (`.nvmrc`, `.tool-versions`, `rust-toolchain`, `go.mod`): don't use features or flags newer than the pin, and never bump the pin as a side effect.
- Watch for portability traps: GNU-only flags (`sed -i`, `date -d`) in scripts macOS users will run, bash-isms in `sh` scripts, tools assumed global instead of project-local.
- If a new tool genuinely earns its place, propose it explicitly — and the same change must make it real: devcontainer/setup script update, CI install, documented prerequisite, version pin. A tool requirement that exists only as a runtime error is a trap.

**Red flags that you're about to violate this:**
- "Everyone has jq installed." (They don't.)
- "This is a one-line script if I use my preferred runtime."
- "The newer version of the tool supports this flag, so I'll use it."
- "It works when I run it." (You're not the one who'll run it.)
- "Installing one extra CLI is not a big ask."
