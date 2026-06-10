---
title: Never Hardcode Absolute Paths
slug: never-hardcode-absolute-paths
category: file-handling
tags: [universal, files, portability]
works_with: all
severity: high
one_liner: "Stops /home/you/project paths from shipping in code that runs anywhere else"
---

# Never Hardcode Absolute Paths

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents machine-specific absolute paths from being baked into code, tests, and config that must run on any other machine.

**[Copy-paste ready version](../../install/never-hardcode-absolute-paths.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant runs `pwd`, sees `/home/dev/projects/acme-api`, and helpfully writes that exact string into a test fixture path, a config default, a script variable, or an import of a data file. It works perfectly — on that machine, in that checkout, today. Then CI clones the repo to `/builds/runner-7/acme-api`, a teammate clones it to `C:\code\acme`, or a Docker build puts it at `/app`, and everything that referenced the absolute path fails with `ENOENT` or, worse, silently reads stale data from a path that happens to exist.

Assistants do this because the absolute path is what their tools return: every `ls`, every file read, every shell command echoes absolute paths back, and copying the observed value into the code is the path of least resistance. The path is true at authoring time. It is a lie everywhere else, and it's a lie that passes local tests, so it routinely survives until CI or a new hire finds it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Hardcode Absolute Paths

NEVER write a machine-specific absolute path into code, tests, scripts, or config. Paths like `/home/<user>/...`, `/Users/<user>/...`, `C:\Users\...`, and `/tmp/<your-session>/...` are facts about your current machine, not about the project.

Code containing your absolute path works exactly once: here, now. It breaks on CI, on teammates' machines, and in containers.

- Derive paths from a stable anchor instead: the script's own location (`Path(__file__).parent`, `path.dirname(__dirname)` patterns, `$(dirname "$0")`), the project root, or an environment variable with a sane default.
- In tests, resolve fixtures relative to the test file or use the framework's tmp-dir facility (`tmp_path`, `t.TempDir()`, `os.tmpdir()`), never a literal `/tmp/test1` or a repo-absolute path.
- In config files, prefer relative paths from the config's own location, or document an env var. If an absolute path is genuinely required (system daemons, deploy targets), it belongs in deployment config with a comment saying why, not in the codebase default.
- Using absolute paths in your own shell commands during the session is fine; the rule is about what you write into files that get committed.
- Before finishing, grep your changes for your own username and working directory. Any hit is a bug.

**Red flags that you're about to violate this:**

- "I'll use the full path so it definitely resolves."
- "The test passes with this path, ship it."
- "Everyone's checkout is probably in a similar place."
- "I'll make it relative later; absolute is fine for now."
- "It's just a default; users can override it."

**Self-check before finishing:** `grep -rn "$HOME\|/Users/\|C:\\\\Users" <changed files>` should return nothing.

---

## Why It Works

1. **It distinguishes session facts from project facts.** The assistant's tools legitimately traffic in absolute paths; the rule draws the line at the write boundary — what goes into committed files — instead of fighting the tooling.
2. **Anchored relative paths are a drop-in replacement, not a sacrifice.** Naming the exact idioms (`__file__`, `dirname "$0"`, `tmp_path`) removes the "but I need a real path" objection.
3. **The final grep is a closed-loop check.** A username in a diff is unambiguous evidence; "did I hardcode anything?" becomes a search with a binary answer.

## Origin

A data-pipeline test fixture loaded its sample CSV via the author's full home-directory path. It passed locally for two weeks of development, then failed on every CI run after merge — but only after a flaky-test quarantine had hidden it for three more days, blocking an unrelated release while someone traced `ENOENT: /home/mk/projects/...` on a runner that had no user named `mk`.
