---
title: No Machine-Specific Values in Committed Config
slug: no-machine-specific-values-in-committed-config
category: configuration
tags: [universal, config, portability]
works_with: all
severity: high
one_liner: "Stops absolute paths, personal ports, and laptop quirks landing in the repo"
---

# No Machine-Specific Values in Committed Config

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from committing configuration that only makes sense on the current machine — absolute home-directory paths, personal port choices, local hostnames.

**[Copy-paste ready version](../../install/no-machine-specific-values-in-committed-config.md)** — just the instruction block, no explanation.

## The Problem

The AI needs a path to the data directory, and it knows one that works: `/Users/sam/projects/app/data`. Into the config file it goes. Or the dev server port becomes 3007 because 3000 was busy here, or the test database host becomes `sams-macbook.local`, or a tool config gains `python: /opt/homebrew/bin/python3.11`. Each value is verifiably correct — the AI can check it right now, on this machine — which is exactly what makes it confident enough to commit it.

These values are landmines with a fuse measured in `git pull`s. The Linux teammate gets a path that doesn't exist. CI gets a hostname it can't resolve. The new hire's first build fails with an error pointing at someone else's home directory, and their first hour at the company is spent learning whose laptop the repo was calibrated for.

AI assistants are unusually prone to this because they resolve paths to absolutes as a matter of course — absolute paths are unambiguous, and ambiguity is what the AI is trying to eliminate. Unambiguous and portable are different properties, and committed config needs the second one.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Machine-Specific Values in Committed Config

NEVER commit a config value that encodes facts about the current machine: absolute paths under a home directory, locally-chosen ports, `*.local` hostnames, usernames, or paths to locally-installed tool versions.

A value that's correct here and meaningless everywhere else doesn't belong in a file everyone shares.

- Paths in committed config must be relative to the project root, or built from a variable (`$HOME`, `${workspaceFolder}`, `%APPDATA%`) — never `/Users/<name>/...` or `C:\Users\<name>\...`.
- Tool locations should be resolved, not pinned: `python3` via PATH, not `/opt/homebrew/bin/python3.11`; if a specific version matters, declare the version requirement (`.tool-versions`, `engines`), not the install path.
- If a value legitimately varies per machine (port, local DB host, browser binary), it belongs in the gitignored local layer (`.env.local`, `*.local.json`, override files) with a portable default in the shared file.
- Hostnames in shared config must be resolvable from every environment that reads them — `localhost` and service names from compose/k8s qualify; `daves-laptop.local` does not.
- Before committing any config change, scan the diff for your own username, home directory, or hostname. Finding one means a value took the wrong exit.

**Red flags that you're about to violate this:**
- "I used the absolute path so there's no ambiguity."
- "I verified this path exists, so the config is correct."
- "The port had to change locally, and committed config is where ports live."
- "Everyone here uses macOS anyway."
- "CI doesn't run this config, so portability doesn't matter."

---

## Why It Works

1. **It breaks the "verified = correct" inference.** The AI commits machine-specific values because it can confirm them locally; the rule redefines correct for shared config as portable, which local verification cannot establish.
2. **The username-in-diff check is mechanical.** "Is this portable?" requires judgment; "does the diff contain `/Users/sam`?" requires grep, and the AI is reliable at grep.
3. **It pairs every per-machine need with a sanctioned destination** (the gitignored local layer), so the rule blocks the bad commit without blocking the underlying need.

## Origin

A test runner config was committed with `chromeBinary: /Users/<dev>/Library/Caches/puppeteer/chrome/mac-119/...` after the assistant fixed a local "Chrome not found" error by pinning the path it discovered. The suite kept passing for the author and failing for everyone else with an error that mentioned a stranger's cache directory. Three developers independently "fixed" it by swapping in their own absolute paths over the following month, each commit breaking the other two, until someone finally made the runner resolve the binary at startup.
