---
title: No Global Package Installs
slug: no-global-package-installs
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "Stops npm install -g and pip install outside a venv for project tooling"
---

# No Global Package Installs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from installing project tools globally, where they're invisible to the repo and missing on every other machine.

**[Copy-paste ready version](../../install/no-global-package-installs.md)** — just the instruction block, no explanation.

## The Problem

The project needs `tsx` to run a script, so the assistant runs `npm install -g tsx`. It needs to format some Python, so it runs `pip install black` straight into the system interpreter. The tool works, the task completes, and the machine the assistant happened to be on now has state that exists nowhere in the repository. The next developer — or the CI runner, or the assistant itself in a fresh session — runs the same script and gets `command not found`.

Global installs are how "works on my machine" gets manufactured. They also collide: a globally installed `typescript@5.6` shadows the project's pinned `5.3`, and now `tsc` behaves differently depending on who runs it. On Python, installing into the system interpreter can break OS tooling outright, which is why modern pip refuses with `externally-managed-environment` unless forced — a refusal assistants sometimes "fix" with `--break-system-packages`, a flag whose name is a complete and accurate warning.

Assistants default to global installs because the tool invocation is the goal and `-g` makes the binary available on `PATH` immediately. The project's manifest, the venv, and the other seventeen machines that will run this code are all outside the frame.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Global Package Installs

NEVER install project tooling globally. No `npm install -g`, no `pip install` outside a virtualenv, no `gem install` into the system Ruby for something the project uses. If the project needs a tool, the project's manifest must say so.

- Add tools to the project: `npm install -D <tool>` and run it via `npx <tool>` or a package.json script; `pip install` inside the project's venv and record it in requirements/pyproject; `cargo add`, `bundle add`, etc.
- For one-off executions, prefer ephemeral runners over installation: `npx <tool>`, `pnpm dlx`, `pipx run`, `uvx`. These leave no global state behind.
- Never use `pip install --break-system-packages` or `sudo pip install`. If pip refuses because the environment is externally managed, the fix is a virtualenv, not force.
- Never use `sudo` with any language package manager. If an install seems to need root, the install location is wrong.
- If a global tool already exists on the machine, don't rely on it — the project must work on a machine that doesn't have it. Check the manifest, not the PATH, to determine what's available.
- Exception: tools the user explicitly asks to install globally for their own machine-wide use. Confirm that's the intent before using `-g`.

**Red flags that you're about to violate this:**
- "I'll install it globally so it's available on the PATH."
- "It's just a CLI tool, it doesn't need to be a project dependency."
- "Global install is quicker than editing package.json."
- "pip is refusing, so I'll pass --break-system-packages."
- "sudo will get around this permissions error."

---

## Why It Works

1. **It makes the manifest the definition of "available."** The AI's check is "does the command run here"; the rule replaces it with "is it declared in the repo," which is the question every other machine will ask.
2. **It supplies the ephemeral-runner pattern** (`npx`, `pipx run`, `uvx`), which covers the legitimate one-off case that global installs were reaching for.
3. **It hard-blocks the two escalation flags** — `--break-system-packages` and `sudo` — that turn a bad habit into a broken operating system.
4. **It carves out the real exception** (user explicitly wants a machine-wide tool) so the rule doesn't get overridden the first time it's inconvenient.

## Origin

An assistant set up a release script that depended on a globally installed CLI it had added with `npm install -g` during development. The script worked for weeks on the one laptop where it was built, then the release had to be cut from CI during an incident — where the global package didn't exist, the script died on `command not found`, and the hotfix release was delayed forty minutes while someone reverse-engineered which unlisted tools the script assumed.
