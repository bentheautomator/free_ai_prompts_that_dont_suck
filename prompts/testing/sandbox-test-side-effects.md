---
title: Sandbox Test Side Effects
slug: sandbox-test-side-effects
category: testing
tags: [universal, testing, isolation]
works_with: all
severity: high
one_liner: "Tests writing real files, env vars, and global state they never clean up"
---

# Sandbox Test Side Effects

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests that scribble on the real filesystem, environment, and globals, leaving wreckage for the next run.

**[Copy-paste ready version](../../install/sandbox-test-side-effects.md)** — just the instruction block, no explanation.

## The Problem

A test needs to verify config loading, so the AI has it write `./config.json` — into the repo's working directory. Another sets `process.env.API_MODE = 'test'` and never sets it back. A third writes to `~/.appname/cache` because that's the path the code uses, monkeypatches a module-level singleton, or registers a global handler. Each test passes. The wreckage surfaces elsewhere: the second run fails because `config.json` already exists; an unrelated test fails because `API_MODE` is still `'test'`; the developer discovers the suite has been quietly rewriting their actual dotfiles; `git status` shows mystery files that someone eventually commits.

AI assistants write tests this way because they mirror the production code's behavior — the code writes to `~/.appname`, so the test exercises exactly that — without registering that tests run *on someone's real machine, repeatedly, in parallel*. Cleanup, when it exists, is an unprotected line at the end of the test body, which means one assertion failure skips it and the leak begins. Pollution bugs are miserable to trace because the symptom (a failing test, a corrupted dotfile) appears far from the cause (a different test, possibly in a different file, possibly last week).

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Sandbox Test Side Effects

Tests must leave the machine exactly as they found it. NEVER write to real user directories, the repo working tree, shared paths, environment variables, or process globals without an automatic, failure-proof restore.

The core problem: leaked side effects outlive the test and corrupt later runs, parallel workers, other tests, and the developer's actual machine — producing failures whose cause is far away from their symptom.

Rules:
- Filesystem: use the framework's managed temp dirs — `tmp_path` (pytest), `t.TempDir()` (Go), `mkdtemp` in setup with teardown removal. Never write into the repo tree, `~`, or hardcoded `/tmp/myapp` paths (which collide under parallel runs)
- If the code under test has a hardwired real path, inject or patch the path for the test (`monkeypatch`, config override, env var the code respects) — don't let the test exercise the real location
- Environment variables: only through restoring mechanisms — `monkeypatch.setenv`, or save-and-restore in setup/teardown. A bare `process.env.X = ...` or `os.environ[...] = ...` in a test body is a leak in waiting
- Globals, singletons, module state, registered handlers, frozen time, network interceptors: every mutation needs a paired restore in teardown — `afterEach`, fixture finalizers, `jest.restoreAllMocks()`, `nock.cleanAll()`
- Cleanup goes in teardown hooks or fixtures, NEVER inline at the end of the test body — an assertion failure skips inline cleanup, so the test leaks exactly when it fails, which is when you least need extra chaos
- Verification: run the test twice in a row, and check `git status` is clean afterward. Second-run failure or new untracked files means you leaked

**Red flags that you're about to violate this:**
- "The test writes the file right here in the project, easy to inspect..."
- "I'll set the env var at the top of the test, it's only for this process..."
- "I added cleanup at the end of the test, after the assertions..."
- "The code always writes to ~/.appname, the test should match reality..."
- "/tmp/test-output is fine, it's temp by definition..."

---

## Why It Works

1. **It names the run-twice reality.** The AI validates a test against a single fresh execution, where leaks are invisible. "Run it twice, then check git status" is a two-minute protocol under which every pollution bug in this class self-identifies.

2. **It explains why inline cleanup is fake cleanup.** The AI genuinely believes appending `os.remove(path)` after the asserts handles it. Pointing out that failures skip those lines — so the test leaks precisely when failing — moves cleanup into teardown for a reason, not a convention.

3. **It breaks the "match reality" trap.** Exercising the code's real `~/.appname` path feels like fidelity. Reframing the test machine as someone's actual computer, hit repeatedly and in parallel, shows that path injection is the faithful design, not a compromise.

## Origin

A CLI tool's test suite passed reliably for everyone except, intermittently, whoever had run it most recently — second invocations tripped over state the first left behind in `~/.config/<tool>/`, including one case where the suite overwrote a maintainer's real saved credentials with fixture values. The tests had been generated by an assistant that faithfully exercised the tool's real config path, cleanup placed neatly after assertions where any failure skipped it. The fix — temp dirs plus an env-var override the code already supported — was 20 minutes of work, located after roughly two years of "weird, works on a fresh machine."
