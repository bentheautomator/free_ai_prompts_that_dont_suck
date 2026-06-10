---
title: Restart the Process Before Verifying
slug: restart-the-process-before-verifying
category: verification
tags: [universal, verification, state]
works_with: all
severity: high
one_liner: "Verifying changes against a long-running process still on the old code"
---

# Restart the Process Before Verifying

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from "verifying" a change against a server that is still running the code from before the change.

**[Copy-paste ready version](../../install/restart-the-process-before-verifying.md)** — just the instruction block, no explanation.

## The Problem

The assistant edits a config file, a route handler, or an environment variable, then curls the dev server to verify — and the server, started twenty minutes ago, is still executing the old code. Whatever the response shows, it isn't evidence about the change. Sometimes this produces a false pass (old code happened to behave acceptably); sometimes a false fail that sends the assistant "fixing" code that was already correct, stacking changes on a working implementation because a stale process kept reporting the old behavior.

The root error is treating "the server is running" as "the server is running my code." Hot reload makes this worse, not better: it works often enough to be assumed and fails silently in exactly the cases that matter — config files, environment variables, dependency changes, anything outside the watcher's globs. The assistant has no memory of having started the process, frequently didn't start it, and never asks whether the running instance postdates the edit.

The failure mode compounds. Every observation taken against a stale process is corrupted evidence, and conclusions drawn from corrupted evidence generate further wrong actions. A whole debugging spiral can be downstream of one unrestarted daemon.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Restart the Process Before Verifying

NEVER use a long-running process to verify a change unless you can establish the process is executing the changed code. "The server responds" is not "the server runs my edit."

The core problem: edits change files, not running processes. Until the process restarts or demonstrably reloads, every observation you take from it describes the old code.

- Before verifying through any persistent process (dev server, watcher, REPL, worker, container), establish freshness: restart it yourself, see the reload logged in its output, or confirm its start time postdates your last edit.
- Treat these as restart-always: environment variables, config files, dependency installs, anything compiled or bundled outside a watcher, schema and fixture changes loaded at boot. Hot reload does not cover them.
- When in doubt, restart. A restart costs seconds; debugging phantom behavior from a stale process costs the rest of the session.
- Distrust suspicious observations in both directions: a pass that came too easily and a failure that makes no sense given your edit are both classic stale-process signatures. Verify freshness before believing either.
- Prove freshness when stakes are high: add a temporary startup log line or version marker, see it in the output, then verify. Remove the marker afterward.
- After restarting, confirm the process actually came back up before testing — a crashed restart looks a lot like a stale process.

**Red flags that you're about to violate this:**
- "The dev server is already running, I'll just hit the endpoint..."
- "Hot reload will have picked that up..."
- "The change didn't take effect? The logic must be wrong, let me edit more..."
- "Restarting feels disruptive; the watcher handles this..."
- "It responded fine, so the change works..."

---

## Why It Works

1. **It splits "running" from "running my code."** The model conflates process liveness with code freshness; naming them as separate facts makes the missing one conspicuous.

2. **It enumerates the hot-reload blind spots.** "When does reload fail?" is exactly the knowledge the model doesn't apply in the moment. A concrete restart-always list converts a judgment call into a lookup.

3. **It flags the symptom pattern.** "Change had no effect, so I'll change more" is the stale-process spiral in one sentence. Tagging inexplicable results as freshness suspects interrupts the spiral at step one.

4. **It offers proof, not just hygiene.** The startup-marker trick gives a positive test for freshness, which matters when restarts are managed by tooling the model doesn't control.

## Origin

An assistant spent most of a session "fixing" an auth middleware that rejected every request. Each fix changed nothing, which prompted deeper fixes, including a rewrite of token parsing that had been correct all along. The dev server had been started before the first edit and never restarted; middleware in that framework loads once at boot. One restart validated the original two-line fix. The rewrite was reverted, and the session transcript became internal training material on stale state.
