---
title: Regenerate Shared Artifacts With Pinned Tool Versions
slug: regenerate-shared-artifacts-with-pinned-tool-versions
category: collaboration
tags: [universal, teamwork, tooling]
works_with: all
severity: medium
one_liner: "Stops regenerating lockfiles and codegen output with the wrong tool version"
---

# Regenerate Shared Artifacts With Pinned Tool Versions

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from regenerating shared artifacts — lockfiles, codegen output, snapshots, compiled schemas — with a different tool version than the team uses.

**[Copy-paste ready version](../../install/regenerate-shared-artifacts-with-pinned-tool-versions.md)** — just the instruction block, no explanation.

## The Problem

Plenty of checked-in files are not written but generated: lockfiles, protobuf/GraphQL/OpenAPI codegen output, formatted snapshots, generated clients, compiled translations. The team generates them with specific tool versions — pinned in `packageManager`, `.tool-versions`, a devcontainer, or just convention — so that regeneration is deterministic and diffs mean something. The AI regenerates one with whatever version its environment happens to have: npm 11 against an npm-9 lockfile, a newer protoc, a different formatter release, the global instead of the project-local binary.

The output is "correct" and also wrong. The lockfile changes format version and rewrites hundreds of lines; the codegen output reorders or restyles everything it touches. Now the diff is unreviewable — three real lines of change buried in five hundred of version noise. The next teammate to regenerate with the *correct* version produces the inverse five-hundred-line diff, and the artifact begins ping-ponging between tool versions with every contributor. Sometimes it's worse than churn: mixed-version lockfiles resolve dependencies differently than CI expects, and codegen from a different version can change runtime behavior, not just formatting.

The AI falls into this because the command is right — `npm install`, `protoc`, `make generate` — and only the binary behind it is wrong. Nothing fails. The artifact regenerates successfully, in the wrong dialect.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Regenerate Shared Artifacts With Pinned Tool Versions

ALWAYS regenerate checked-in artifacts with the exact tool version the project pins. A generated file's format is a team-wide agreement enforced by tool version; regenerating with a different version rewrites the agreement for everyone.

Wrong-version regeneration succeeds silently — the only symptom is a huge diff and a teammate's inverse diff next week.

- Before regenerating anything checked in (lockfiles, codegen output, snapshots, generated clients/types/docs), find the pinned version: `packageManager` field, `engines`, `.tool-versions`, `.nvmrc`, devcontainer, CI workflow, or the project's documented setup. Use that version.
- Prefer the project's own invocation path — `make generate`, the npm script, the repo-local binary (`node_modules/.bin/`, `./gradlew`), `corepack`/version-manager shims — over whatever is globally installed.
- If your environment can't provide the pinned version, stop. Say which version is required and which you have. Do not regenerate with the wrong one "to keep moving."
- Inspect the diff after regenerating. If the change is far larger than your input change — wholesale reordering, format-version bumps, mass restyling — suspect a version mismatch and don't commit it.
- Never hand-edit generated files to dodge the tooling question; that breaks the artifact differently.
- If the task is genuinely to upgrade the generator, that's its own change: bump the pin, regenerate everything, and label the diff as mechanical.

**Red flags that you're about to violate this:**
- "I have a newer version; the output will be fine."
- "The lockfile diff is big, but lockfile diffs are always big."
- "I'll use the global binary; same tool either way."
- "Regenerating is the standard command, version can't matter much."
- "I'll just hand-edit the generated file instead."

---

## Why It Works

1. **It locates the pin before the run** — the failure is invisible at execution time, so the only effective checkpoint is before the command, not after.
2. **It routes through repo-local invocation paths**, which are the project's own mechanism for answering "which version" correctly without anyone thinking about it.
3. **It uses diff size as a tripwire**: output disproportionate to input is the one observable symptom of version mismatch, and the rule turns it into a stop signal instead of background noise.
4. **It prevents the ping-pong equilibrium**, where an artifact alternates formats between contributors and every diff containing it becomes permanently unreviewable.

## Origin

An assistant adding one dependency ran the install with a package manager two major versions ahead of the project's pin. The lockfile silently migrated formats: a 4,000-line diff for a one-package change, which got merged because nobody reviews 4,000 lockfile lines. CI, running the pinned version, resolved several transitive dependencies differently than local machines did, producing a works-locally-fails-in-CI mystery that consumed two engineers for a day. The following week, a teammate's routine install regenerated the 4,000 lines back.
