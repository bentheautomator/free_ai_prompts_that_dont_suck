---
title: Resolve Paths, Don't Assume the CWD
slug: resolve-paths-dont-assume-cwd
category: file-handling
tags: [universal, files, shell]
works_with: all
severity: medium
one_liner: "Stops code and commands that only work from one particular directory"
---

# Resolve Paths, Don't Assume the CWD

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents scripts, commands, and file operations that silently depend on being run from a specific working directory.

**[Copy-paste ready version](../../install/resolve-paths-dont-assume-cwd.md)** — just the instruction block, no explanation.

## The Problem

A script opens `./config.yaml`, the assistant tests it from the repo root, it works, done. Then a cron job runs it from `/`, a user runs it from `scripts/`, or CI runs it from a different checkout layout, and the relative path resolves against the *caller's* directory, not the script's. Best case: `FileNotFoundError`. Worst case: the path exists in both places and the script silently reads or — far worse — writes the wrong file. The same trap hits the assistant's own session work: after a few `cd`s in earlier commands, it operates on `./src/utils.py` assuming a cwd that changed three tool calls ago, and edits a path that doesn't exist or creates a stray file in the wrong directory.

The cwd is ambient mutable state. Code that consumes it without declaring it works only by coincidence of invocation, and the coincidence holds right up until automation — cron, systemd, CI, a git hook (which runs from the repo root... usually) — invokes it from somewhere else.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Resolve Paths, Don't Assume the CWD

NEVER write code or run commands whose correctness depends on an unverified current working directory. Anchor every relative path to something stable.

The cwd is set by the caller, not by you, and every invoker — cron, CI, a user in a subdirectory — sets it differently.

- In scripts, resolve relative to the script's own location: `SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)` in bash, `Path(__file__).resolve().parent` in Python, `__dirname`/`import.meta.url` in Node. Then build paths from that anchor.
- In application code, resolve relative to an explicit root passed in via argument, env var, or config — not whatever `process.cwd()` happens to be, unless cwd-relative is the documented contract (CLI tools acting on the user's directory).
- In your own shell work, prefer absolute paths in commands. Don't carry cwd assumptions across multiple commands; a `cd` earlier in the session is state you'll forget. Verify with `pwd` if anything depends on it.
- `cd` inside scripts changes state for everything after it; if you must, use a subshell `(cd dir && ...)` so the change can't leak.
- Files you create land relative to the cwd too: a "local" output file written from the wrong directory is a stray artifact in a random location.
- Before shipping a script, ask: what happens if this runs from `/`? If the answer is "breaks" or "writes somewhere weird," anchor the paths.

**Red flags that you're about to violate this:**

- "It works when I run it from the repo root, and that's how people run things."
- "I cd'd earlier, so relative paths are fine from here."
- "The config file is at ./config.yaml." (Relative to what, exactly?)
- "Cron will run it the same way I did."
- "I'll fix the paths if someone hits a problem."

---

## Why It Works

1. **It names the cwd as caller-controlled state**, which reframes "the path works" as "the path works for one caller" — the precise gap automation falls through.
2. **The script-relative anchor idioms are drop-in** (`dirname "$0"`, `__file__`, `__dirname`), so correctness costs one line instead of a redesign.
3. **The "what if this runs from /" question is a portable thought experiment** that surfaces both failure modes — missing files and misplaced writes — before an invoker does it for real.

## Origin

A backup script tested interactively from the project root wrote its archive to `./backups/`. Promoted to cron, it ran with cwd `/` and spent six weeks faithfully writing backups to `/backups` on the root partition: the monitoring checked the cron exit code (0), the restore drill checked the project's `backups/` directory (six weeks stale), and the disk-full alert is what finally explained the discrepancy.
