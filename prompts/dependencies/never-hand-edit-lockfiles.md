---
title: Never Hand-Edit Lockfiles
slug: never-hand-edit-lockfiles
category: dependencies
tags: [universal, dependencies, lockfiles]
works_with: all
severity: high
one_liner: "Stops manual lockfile edits that corrupt integrity hashes and resolution state"
---

# Never Hand-Edit Lockfiles

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from editing lockfile entries directly instead of letting the package manager write them.

**[Copy-paste ready version](../../install/never-hand-edit-lockfiles.md)** — just the instruction block, no explanation.

## The Problem

A lockfile looks like an ordinary text file, and AI assistants treat it like one. Asked to bump a dependency, an assistant will sometimes open `package-lock.json`, find the `"version"` field for the package, and edit it directly — the same way it would edit any other JSON. Sometimes it goes further and edits the `resolved` URL to match. It almost never touches the `integrity` hash, because it can't compute one.

The result is a lockfile that lies. The version says 4.2.1, the integrity hash still belongs to 4.1.0, and the next `npm ci` either fails with an integrity error or — worse on some tooling — installs something other than what the file claims. Yarn and pnpm lockfiles have their own internal bookkeeping (resolution keys, peer dependency suffixes, checksums) that hand edits silently break. The package manager is the only writer that keeps all of these fields consistent.

This happens because editing files is the assistant's primary tool, and a one-line version bump in a JSON file looks like the smallest possible change. It doesn't model the lockfile as machine-generated output with internal invariants, any more than it would hesitate to edit a config file.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Hand-Edit Lockfiles

NEVER edit a lockfile directly. `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `poetry.lock`, `Gemfile.lock`, and friends are machine-generated output with internal invariants (integrity hashes, resolution keys, dependency graphs) that only the package manager can keep consistent.

- To change a version, edit the manifest (`package.json`, `pyproject.toml`, `Cargo.toml`) or use the manager's command (`npm install pkg@4.2.1`, `cargo update -p pkg`, `poetry update pkg`), then let the tool rewrite the lockfile.
- Never change `version`, `resolved`, or `integrity` fields in a lockfile by hand, even if the edit looks trivially correct. You cannot compute the integrity hash, so the file becomes internally inconsistent.
- Never "fix" a lockfile parse error or schema complaint by editing the file. Regenerate it through the package manager and check the diff.
- If a lockfile entry must change for a transitive dependency, use the supported mechanism: `overrides` in package.json, `resolutions` in yarn, `pnpm.overrides`, or `cargo update -p` — then run install so the lockfile is rewritten by the tool.
- Treat any task plan that includes "edit the lockfile" as a planning error. The correct verb for lockfiles is "regenerate," never "edit."

**Red flags that you're about to violate this:**
- "It's just JSON, I'll bump the version field directly."
- "Editing the lockfile is faster than running the whole install."
- "I'll update the resolved URL too, so it stays consistent."
- "The install environment isn't available, so I'll write the lockfile change manually."
- "Only one entry needs to change, no need to involve the package manager."

---

## Why It Works

1. **It separates the writable surface from the generated surface.** The AI treats all text files as equally editable; explicitly classing lockfiles as machine output removes that assumption.
2. **It names the field the AI can't fake** — the integrity hash — which makes the impossibility concrete instead of procedural. The AI can't argue its way around a checksum it cannot compute.
3. **It routes every legitimate need through a supported mechanism** (manifest edits, overrides, targeted update commands), so "but I need to change a transitive version" has an answer that isn't hand-editing.
4. **It corrects the verb.** "Regenerate, never edit" gives the AI a planning-level rule it can apply before any file is opened.

## Origin

Asked to pin a transitive dependency that had a bad release, an assistant edited the package's `version` field in `package-lock.json` and left the integrity hash untouched. Local `npm install` quietly reconciled the file, but `npm ci` in the deployment pipeline failed with `EINTEGRITY` on every branch that included the commit. Three other PRs rebased onto it before anyone traced the red pipeline back to a single hand-edited lockfile line.
