---
title: Check Runtime Support Before Package Installs
slug: check-runtime-support-before-package-installs
category: dependencies
tags: [universal, dependencies, versions]
works_with: all
severity: high
one_liner: "Stops installing packages that require a newer Node or Python than prod runs"
---

# Check Runtime Support Before Package Installs

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from adding a package whose minimum runtime version is newer than what the project actually runs.

**[Copy-paste ready version](../../install/check-runtime-support-before-package-installs.md)** — just the instruction block, no explanation.

## The Problem

Packages declare runtime floors — `"engines": { "node": ">=20" }`, `requires-python = ">=3.11"` — and projects have runtime ceilings: the Node 18 in production, the Python 3.9 on the data team's cluster, the version the Docker base image actually contains. AI assistants connect the two only by accident. They pick the latest version of a package, install it on a dev machine running a current runtime, watch it work, and ship it toward a production environment running something older.

How this surfaces depends on luck. The lucky version is an `EBADENGINE` warning or an outright pip resolution error. The unlucky version installs fine — engines warnings are non-fatal by default — and fails at runtime with a `SyntaxError` on a language feature the old runtime doesn't parse, or an ImportError deep in the package, in production, at night. The truly cursed variant is the assistant noticing the engine conflict and "fixing" it by editing the project's own `engines` field or Dockerfile base image to satisfy the package — upgrading the entire runtime of a production service as an unexamined side effect of adding a date library.

The root cause is that "works here" is the assistant's only test, and the dev environment is usually newer than every environment that matters.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check Runtime Support Before Package Installs

ALWAYS check a package's minimum runtime requirement against the oldest runtime the project actually targets before adding or upgrading it. "It installs on my machine" only proves compatibility with the machine that matters least.

- Find the project's true floor first: the `engines` field, `.nvmrc`, `requires-python`, the Dockerfile's `FROM` line, and CI's version matrix. The constraint is the oldest of these, not whatever the dev shell runs.
- Check the package's floor before installing: `npm view <pkg> engines`, the PyPI page's "Requires: Python" line, or the package docs. For an upgrade, check the new version's floor — packages routinely raise it in majors and sometimes in minors.
- If the package's floor exceeds the project's, pick the newest package version that still supports the project's runtime (registries keep them all; `npm view <pkg>@'*' engines` shows the history) — or surface the conflict to the user.
- NEVER resolve the conflict by raising the project's runtime — editing `engines`, bumping the Dockerfile base image, or changing CI's version matrix — as a side effect of adding a package. A runtime upgrade is its own project with its own testing, decided by humans.
- Treat `EBADENGINE` and similar warnings as failures, not noise. A non-fatal warning at install time is frequently a fatal error at runtime on the older target.

**Red flags that you're about to violate this:**
- "It installed and ran cleanly, so compatibility is fine."
- "The engines warning is non-blocking; npm installed it anyway."
- "Everyone is on Node 22 by now."
- "I'll just bump the base image to make the requirement go away."
- "The latest version is the best version to install."

---

## Why It Works

1. **It redefines the compatibility question** from "does it work where I am" to "does it work on the project's oldest target," and tells the AI exactly which files encode that target.
2. **It makes the package-side check a command** (`npm view <pkg> engines`), turning an abstract concern into a two-second lookup with a comparable answer.
3. **It explicitly forbids the inverted fix** — upgrading the runtime to satisfy the package — which is the most damaging variant because it ships an infrastructure change disguised as a dependency add.
4. **It reclassifies the warning the AI scrolls past.** `EBADENGINE` is currently filtered as noise; naming it a failure changes the triage.

## Origin

An assistant upgraded a validation library to its latest major while adding a feature; the new major required a Node version two LTS lines ahead of production. Local dev (on current Node) was fine, CI (on a current image) was fine, and the staging deploy crashed on boot with a syntax error inside `node_modules` — the old runtime couldn't parse the package's modern output. The deploy rollback was easy; the awkward part was discovering the assistant had also "helpfully" bumped the `engines` field to silence the install warning, which had stopped CI from catching exactly this.
