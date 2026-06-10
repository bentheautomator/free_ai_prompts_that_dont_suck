---
title: Never Load Example Config as Live Config
slug: never-load-example-config-as-live-config
category: configuration
tags: [universal, config, templates]
works_with: all
severity: critical
one_liner: "Stops apps from quietly booting on .env.example placeholder values"
---

# Never Load Example Config as Live Config

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from wiring example/template config files into the live config load path, or "fixing" a missing-config error by loading the template.

**[Copy-paste ready version](../../install/never-load-example-config-as-live-config.md)** — just the instruction block, no explanation.

## The Problem

The app won't boot because `config.yml` is missing. The AI spots `config.example.yml` sitting right there and does the helpful thing: adds a fallback — "if config.yml doesn't exist, load the example." Boot fixed. What it actually built is a machine for running production on placeholder values. The example file's job is to be a *dead* document: a template humans copy and fill in. The moment code reads it, every placeholder in it — `host: changeme`, `api_key: xxx`, `db: myapp_dev` — becomes a live default that activates exactly when real config is missing, which is exactly when you need a loud failure.

The same failure has quieter variants the AI also produces: copying `config.example.yml` to `config.yml` automatically in a setup script or Dockerfile (now the placeholders ship), pointing tests at the example file (now tests "validate" config no environment uses), or editing the example file believing it changes behavior — and concluding the config system is broken when nothing changes.

A missing config file is the system working: it's the fail-fast you want. Bridging it with the template converts a clear startup error into an app that runs, takes traffic, and does placeholder things to real data.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Load Example Config as Live Config

NEVER make application code read an example or template config file (`.env.example`, `config.sample.yml`, `settings.dist.php`, `*.template`). These files are documentation for humans to copy — the moment code loads one, its placeholders become live values.

An app that won't boot without real config is correct. An app that boots on placeholders is a delayed incident.

- No fallback chains that end at a template: `config.yml, else config.example.yml` turns "deployment forgot the config" into "production runs on `changeme`."
- Don't auto-copy templates into place in Dockerfiles, entrypoints, setup scripts, or CI. Copying is a human act that comes with filling in values; automated copying ships the placeholders.
- A missing-config error is a feature. The fix is to provision real config (or tell the user to), not to widen the search path until something loads.
- Don't point tests at example files — tests should construct their own config or use dedicated fixtures, so the example stays a pure template and tests validate real shapes.
- Setup tooling may *detect* a missing config and print "copy config.example.yml to config.yml and edit it" — instruct, don't perform.
- If you edit an example file expecting behavior to change, stop: nothing reads it (and nothing should). Find the live config instead.

**Red flags that you're about to violate this:**
- "Falling back to the example file makes the app work out of the box."
- "The setup script can copy the template automatically to save a step."
- "The example values are reasonable defaults anyway."
- "Tests can just load config.example.yml, it has all the keys."
- "The boot error says config.yml is missing — easiest fix is to load what exists."

---

## Why It Works

1. **It reclassifies the missing-config error as correct behavior,** which blocks the AI's core motivation — error-makes-app-boot — from selecting the template as a fix.
2. **It names the activation condition:** template fallbacks fire precisely when real config is absent, i.e., precisely when a loud failure is most valuable, so the fallback always converts the best-case failure into the worst-case success.
3. **It separates detection from performance** — tooling that instructs a human to copy and fill preserves the template's contract, tooling that copies it destroys it.
4. **It covers the read-side confusion too:** flagging edits to example files as no-ops saves the "config system is broken" debugging spiral.

## Origin

A containerized service's entrypoint script copied `config.example.yml` into place when no config was mounted — added long ago so the container would "just run" in demos. A Kubernetes manifest typo unmounted the real config on one deployment, the entrypoint quietly substituted the template, and the service came up healthy, pointed at the placeholder database name. It served empty results to a fraction of traffic for nine hours. Every readiness check passed the entire time, because an app running on placeholders is, in the narrowest sense, running.
