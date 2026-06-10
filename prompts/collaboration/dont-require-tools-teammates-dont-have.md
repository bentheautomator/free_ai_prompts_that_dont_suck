---
title: Don't Require Tools Teammates Don't Have
slug: dont-require-tools-teammates-dont-have
category: collaboration
tags: [universal, teamwork, tooling]
works_with: all
severity: medium
one_liner: "Stops adding runtimes and CLIs to the workflow that nobody else has installed"
---

# Don't Require Tools Teammates Don't Have

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from making the project depend on runtimes, CLIs, or tool versions that the rest of the team doesn't have installed.

**[Copy-paste ready version](../../install/dont-require-tools-teammates-dont-have.md)** — just the instruction block, no explanation.

## The Problem

The AI solves its task with a tool, and quietly the tool becomes a requirement. It writes the new build step as a script needing a runtime the team doesn't use ("just needs Bun"), wires `jq`, `yq`, or `ripgrep` into a Makefile target everyone runs, generates code with a CLI nobody else has, uses syntax that only works on the newest version of a tool the team has pinned older, or assumes GNU coreutils in a script half the team will run on macOS. On the AI's path, everything works — its environment has whatever it needed, or it never actually ran the script at all.

Everyone else inherits a scavenger hunt. The Makefile fails with `command not found`. The setup instructions silently stopped being sufficient. The new hire's onboarding, which used to be "clone and make," now includes an unlisted side quest discovered one error message at a time. Tool requirements are the most regressive tax in a codebase: the people who pay most are the ones with the least context — new teammates, occasional contributors, the person from another team trying to run your tests once.

This happens because the AI's view of "the environment" is its own. A tool that resolves on its PATH is, as far as it can tell, a tool that exists. The team's actual common denominator — what's in the devcontainer, what setup docs install, what CI installs — is the real environment, and it's defined in files the AI didn't consult.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It redefines "the environment" as the team's declared one** — devcontainer, CI, setup docs — replacing the AI's only natural reference point, which is its own PATH.
2. **It biases toward the incumbent stack**, where the dependency cost is already paid, instead of importing a new runtime to save ten lines.
3. **It enumerates the silent portability traps** (GNU vs. BSD, version-gated flags, bash-isms) that pass on one machine and fail on the next, which no amount of local testing reveals.
4. **It makes new tools all-or-nothing**: either the requirement is installed everywhere the team's environment is defined, or it doesn't ship — eliminating the discovered-by-error-message middle state.

## Origin

An assistant rewrote a team's release script to use a YAML CLI it favored, plus a `sed -i` flag that only works on GNU sed. It tested clean in the assistant's Linux environment. The next release was cut by an engineer on macOS: forty minutes lost to `command not found`, a brew install, and then silently mangled output from the BSD `sed` incompatibility — caught only because the changelog it generated looked wrong. The script had worked perfectly for exactly one environment: the one that wrote it.
