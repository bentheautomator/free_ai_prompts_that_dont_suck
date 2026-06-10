---
title: Log or Rethrow, Never Both
slug: log-or-rethrow-never-both
category: error-handling
tags: [universal, errors, logging]
works_with: all
severity: medium
one_liner: "AI logging the same exception at every layer it passes through"
---

# Log or Rethrow, Never Both

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents one failure from appearing as four stack traces in the logs and tripping alerts four times.

**[Copy-paste ready version](../../install/log-or-rethrow-never-both.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to "add error handling and logging" across a codebase and every layer gets the same treatment: `catch (e) { logger.error("...", e); throw e; }`. The repository logs the error and rethrows. The service layer catches it, logs it, rethrows. The controller logs it again. The framework's top-level handler logs it a fourth time. One database timeout is now four ERROR entries with four stack traces — same exception, four different messages, four timestamps a few milliseconds apart.

The cost isn't aesthetic. Error-rate dashboards now count one incident as four. Alerts keyed to ERROR volume fire at 4x reality. And during diagnosis, an engineer scanning logs must figure out which entries are distinct failures and which are echoes — at 3 a.m., that triage is where minutes go to die. Worse, the duplicated pattern trains the team to skim past repeated stack traces, which is exactly how the genuinely new error in the middle gets missed.

The model writes log-and-rethrow at every layer because each catch block is generated locally: at *this* layer, logging seems prudent, and rethrowing seems safe. Nobody — human or model — is looking at the four layers stacked together.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Log or Rethrow, Never Both

Each error should be logged exactly once, at the layer that finally handles it. When you rethrow, do not also log — the layer that ultimately catches will do the logging.

A catch block has two jobs to choose from: take responsibility (handle and log) or pass responsibility (rethrow, optionally adding context). Doing both at every layer turns one failure into a log storm.

- `catch (e) { logger.error(e); throw e; }` is the antipattern — pick one: handle-and-log, or rethrow
- When rethrowing through a layer, add context to the exception itself (wrap with cause: `raise JobError(f"syncing user {uid}") from e`), not to the logs — context travels with the error to the single log site
- Log at the boundary where the error stops propagating: the top-level request handler, the job runner, the consumer loop — once, with the full chained stack trace
- Exception: a layer that handles the error (retries successfully, falls back deliberately) may log it at WARN/INFO as a handled event — because for layers above, that error no longer exists
- Trust the propagation: "log here too in case it gets swallowed upstream" means you suspect a swallowing bug — fix that bug instead of pre-compensating with duplicate logs
- When adding logging to existing code, check whether the exception is already logged above or below before adding another site

**Red flags that you're about to violate this:**
- "I'll log it here for visibility and rethrow so the caller can deal with it..."
- "Extra logging never hurts..."
- "Each layer should record that it saw the error..."
- "Better to log twice than risk losing it..."
- "I'll add logger.error to every catch block for consistency..."

---

## Why It Works

1. **It gives every catch block a binary identity.** "Take responsibility or pass it" replaces the model's vague sense that each layer should "do something" — and log-and-rethrow is precisely the option that does both halves badly.

2. **It reroutes the context urge productively.** The legitimate instinct behind per-layer logging is that each layer knows something useful; directing that context into exception wrapping preserves the information while collapsing the log sites to one.

3. **It names the distrust rationalization.** "In case it gets swallowed upstream" is the actual thought behind defensive duplicate logging; surfacing it converts a logging decision into a bug to fix.

4. **It carves out handled errors cleanly.** Retried-and-recovered failures deserve a record without being errors anymore; the WARN-for-handled rule prevents the model from reading "log once" as "never log unless fatal."

## Origin

A platform team's error dashboard showed a 4x spike after an assistant performed a codebase-wide "improve logging" pass that added log-and-rethrow to every catch block. Alert thresholds, tuned to historical volume, paged the on-call three times in one night for ordinary failure rates. The cleanup was a second full pass deleting most of what the first pass added — and one real incident during that window was triaged late because its stack trace looked like just another echo.
