---
title: Never Uninstall Global Packages to Fix Conflicts
slug: never-uninstall-global-packages-to-fix-conflicts
category: code-safety
tags: [universal, dependencies]
works_with: all
severity: high
one_liner: "AI removing or upgrading system-wide tools that other projects depend on"
---

# Never Uninstall Global Packages to Fix Conflicts

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from solving one project's dependency conflict by mutating the whole machine's toolchain.

**[Copy-paste ready version](../../install/never-uninstall-global-packages-to-fix-conflicts.md)** — just the instruction block, no explanation.

## The Problem

The project wants Node 20 and the machine has Node 22, so the AI uninstalls Node 22 and installs Node 20 — globally. Three other projects on the machine wanted Node 22. Or a Python package conflicts with a globally installed version, so the AI `pip uninstall`s the global one, breaking a system tool that imported it. Or it `brew uninstall`s a library that "conflicts," and that library was a dependency of half the formulae on the machine. The project compiles; the machine degrades.

The blast radius mismatch is the heart of it: the AI's world is the current project, but global package state is shared infrastructure for every project, system script, and tool on the machine. The AI never inventories who else depends on what it's removing — it can't see those dependents, and it doesn't look. Version managers, virtual environments, and per-project installs exist specifically so this category of mutation never has to happen. The AI skips them because the global mutation is one command and the isolated setup is three.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Uninstall Global Packages to Fix Conflicts

NEVER uninstall, downgrade, or upgrade globally installed packages, runtimes, or tools to resolve one project's dependency conflict. Global state is shared infrastructure — other projects, system scripts, and tools depend on it, and you cannot see those dependents from inside this project.

The core problem: the conflict is project-scoped, but the "fix" is machine-scoped. Removing the global Node/Python/library that bothers this project breaks every other thing that wanted it.

- Solve version conflicts with isolation, never with global mutation: version managers (nvm, pyenv, rbenv, asdf, mise), virtual environments, project-local installs (`npm i` without `-g`), containers, or tool pins (`.nvmrc`, `.python-version`).
- Before any global change that the user explicitly approves, enumerate dependents where possible: `brew uses --installed <formula>`, reverse-dependency queries (`apt-cache rdepends`, `dnf repoquery --whatrequires`), `npm ls -g`. "Nothing else uses it" is a claim that requires evidence.
- Never `pip uninstall` from the system/global Python. System tools import those packages. If you're not inside a venv, you are standing on shared ground.
- Never remove a runtime to install a different major version. Versions coexist via managers; that's what managers are for.
- If the machine genuinely lacks isolation tooling, propose installing the version manager — a strictly additive change — rather than swapping global versions.
- Anything reaching for `sudo apt remove`, `brew uninstall`, `npm -g rm`, or a global upgrade needs explicit user approval with the dependents listed.

**Red flags that you're about to violate this:**
- "The global version is conflicting — simplest to remove it..."
- "I'll upgrade the system Python to match the project..."
- "Nothing else on this machine probably uses that package..."
- "Uninstall and reinstall the right version, quick fix..."
- "Setting up a version manager is overkill for one conflict..."

---

## Why It Works

1. **It names the scope mismatch.** "Project-scoped problem, machine-scoped fix" is a test the AI can run on any proposed command; everything that fails the test has an isolation-based alternative.

2. **It demands evidence for 'nothing else uses it.'** The AI asserts emptiness it never checked. Requiring an actual reverse-dependency query converts the assumption into a lookup — which routinely returns a list, not nothing.

3. **It makes the additive path the sanctioned one.** Installing a version manager solves the same conflict with zero subtraction; explicitly endorsing it removes the "but I had to change something globally" defense.

## Origin

To satisfy a project pinned to an older Python, an assistant uninstalled the machine's newer Python and installed the pinned version system-wide. The OS's own tooling — package manager hooks, a backup script, two CLI utilities — had been running on the removed interpreter. The developer noticed when system updates started failing, days later, and the path from "updates fail" back to "an AI swapped my Python last Tuesday" was not a short one. pyenv would have solved the original problem in two commands, both additive.
