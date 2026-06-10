---
title: Diagnose Import Errors Before Installing
slug: diagnose-import-errors-before-installing
category: dependencies
tags: [universal, dependencies]
works_with: all
severity: medium
one_liner: "Stops the ModuleNotFoundError reflex-install when the real bug is environment"
---

# Diagnose Import Errors Before Installing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from answering every import error with an install command when the package is usually already there.

**[Copy-paste ready version](../../install/diagnose-import-errors-before-installing.md)** — just the instruction block, no explanation.

## The Problem

`ModuleNotFoundError: No module named 'requests'` triggers an almost autonomic response in AI assistants: `pip install requests`. Same with `Cannot find module 'lodash'` and `npm install lodash`. But in an established project, a missing-module error usually doesn't mean the package is missing from the project — it means the command ran in the wrong place. The wrong virtualenv is active. The script ran with system Python instead of `poetry run`. `node_modules` hasn't been installed yet in this fresh clone. The working directory is a monorepo subpackage that doesn't own that dependency.

Reflex-installing into whatever environment happens to be active "fixes" the error while making the system worse. Now there's a stray copy of requests in the system interpreter, possibly at a different version than the project pins, masking the environment misconfiguration that will resurface as something stranger later. In a monorepo, the reflex adds the dependency to the wrong package's manifest, and the real owner still can't resolve it. The error message said "I can't find it from here" and the assistant heard "it doesn't exist anywhere."

The reflex is pure pattern completion: error names a module, command installs a module, loop closes. Diagnosis — *which interpreter ran, what can it see, is the package already declared* — takes three commands the reflex never runs.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Diagnose Import Errors Before Installing

NEVER respond to a missing-module error by immediately installing the module. In an existing project, the most common cause is environmental — wrong interpreter, missing install step, wrong directory — and installing into the wrong environment masks the real bug while adding a stray copy.

- First, check whether the project already declares the dependency: look in `package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`. If it's declared, the package is not missing — your environment is wrong, and installing again is the wrong move.
- Identify what actually executed: `which python` / `python -c "import sys; print(sys.prefix)"` to see if the venv is active; check whether the command should be `poetry run`, `pnpm exec`, or run from a different directory.
- For a fresh clone or new shell, the fix is usually the project's setup step — `npm install`, `poetry install`, activating the venv — not adding a package.
- In a monorepo, confirm which workspace owns the failing file before adding anything, and add the dependency to that workspace's manifest, not the root and not whatever directory you're standing in.
- Only when you've confirmed the package is genuinely absent from the project's declarations is installing it the right fix — and then it goes through the project's package manager, into the manifest, like any new dependency.

**Red flags that you're about to violate this:**
- "Module not found — installing it will fix this."
- "Fastest path to unblocking the script is pip install."
- "It's probably just not installed yet." (declared where? checked?)
- "I'll install it here; the environment details don't matter for now."
- "The error literally tells me what package to install."

---

## Why It Works

1. **It inverts the default interpretation of the error.** "Can't find it from here" versus "doesn't exist" is the precise misreading; the rule installs the correct reading as the first hypothesis for existing projects.
2. **It puts the manifest check first** — one file read that resolves most cases instantly, and that distinguishes "missing dependency" from "broken environment" with certainty.
3. **It names the cost of the reflex** (a stray copy at the wrong version, masking the real misconfiguration), which the AI otherwise never perceives because the error message goes away.
4. **It still permits the install** when diagnosis confirms genuine absence, so the rule reads as "diagnose first," not "never install," and survives contact with real work.

## Origin

A test suite started failing with a missing-module error after a CI image update. An assistant "fixed" it by adding a `pip install` line for that one module into the CI script. The real problem was that the image change had broken the venv activation step, so tests were running against system Python — meaning every dependency now resolved from outside the lockfile's control. The visible error was patched; the invisible drift took three weeks to produce a version-skew bug subtle enough to reach staging, and another two days for anyone to connect it to the "harmless" CI fix.
