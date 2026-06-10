---
title: Derive Environment Configs From a Base
slug: derive-environment-configs-from-a-base
category: configuration
tags: [universal, config, environments]
works_with: all
severity: high
one_liner: "Stops per-environment config files drifting apart one copy-paste at a time"
---

# Derive Environment Configs From a Base

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from maintaining per-environment config as full independent copies that drift, instead of a shared base plus minimal per-environment diffs.

**[Copy-paste ready version](../../install/derive-environment-configs-from-a-base.md)** — just the instruction block, no explanation.

## The Problem

`development.yml`, `staging.yml`, and `production.yml` each contain the complete configuration — eighty keys apiece, seventy-five of them identical. They started as copies of each other. Then a retry setting got tuned in production but not staging. A new cache key got added to dev and staging but the production edit was forgotten. An old key was deleted from two files out of three. Two years later the environments differ in nineteen keys, and nobody can say which differences are intentional. Staging no longer rehearses production; it rehearses a sibling that grew up in a different house.

AI assistants accelerate the drift on both ends. Asked to add a setting, they add it to the file they're testing against and maybe — maybe — the others. Asked to create a new environment, they copy an existing file wholesale, freezing today's accidental drift into a new artifact. Copy-paste is the path of least resistance, and full-copy config files make every change a multi-file synchronization problem that nothing enforces.

The structural fix: common values live once, in a base; per-environment files contain *only* what genuinely differs. Then drift isn't a risk you manage — it's a diff you can read.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Derive Environment Configs From a Base

Per-environment config files must contain ONLY the values that genuinely differ for that environment, layered over a shared base. NEVER maintain full parallel copies of the configuration per environment, and NEVER create a new environment by duplicating an existing one's full file.

Identical keys duplicated per environment is drift with a delay timer: every shared-value change becomes an N-file edit that someone will eventually do in N-1 files.

- Use whatever layering the stack supports: `base.yml` + `production.yml` overlay, `application.yml` with profile overrides, Kustomize bases, shared defaults imported by env files. If the project already layers, respect the layering — add common values to the base, not to each environment.
- A value identical across all environments belongs in the base. Period. If you're about to paste the same key into three files, you're putting it in the wrong place.
- A value in an environment overlay should make a reader ask "why is this different here?" — and the answer should be obvious or commented. Overlays are for differences, and differences are claims.
- When you find existing duplication (same key, same value, three files), flag it; consolidating to base is usually cheap and always worth mentioning.
- If true layering doesn't exist and can't be added now, simulate the discipline: make every multi-environment edit to all files in one change, and say explicitly which files you touched.
- New environment = new minimal overlay over the base, never a copy of staging's file with the names changed.

**Red flags that you're about to violate this:**
- "I'll add the key to production.yml later once it's tested in dev."
- "Copying staging.yml is the fastest way to set up the new environment."
- "The files are mostly the same, keeping them in sync by hand is fine."
- "I don't want to touch the base file, the overlay is safer."
- "This value is the same everywhere, but each file having it is more explicit."

---

## Why It Works

1. **It changes the unit of review from 'three files in sync' to 'one diff per difference.'** Humans and AIs both fail at verifying synchronization; both succeed at reading a ten-line overlay.
2. **It makes drift structurally impossible for shared values** — a value that exists once cannot diverge — instead of procedurally discouraged, which is the regime that produced the drift.
3. **It turns every overlay entry into a documented claim.** When per-env files hold only differences, an unexplained difference stands out instead of hiding among seventy identical lines.

## Origin

An incident review found that a queue's visibility timeout had been tuned in production eight months earlier, during a previous incident, by editing `production.yml` directly. Staging kept the old value, so the load test that "validated" a subsequent consumer rewrite ran under different queue semantics than production — and the rewrite, certified by staging, immediately double-processed jobs in production. The remediation collapsed three 80-key files into one base and three overlays totaling eleven keys, at which point two more unintentional differences nobody knew about fell out of the diff.
