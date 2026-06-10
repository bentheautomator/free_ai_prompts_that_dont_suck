---
title: Read Config at Call Time, Not Import Time
slug: read-config-at-call-time-not-import-time
category: configuration
tags: [universal, config]
works_with: all
severity: high
one_liner: "Stops config frozen at module import from ignoring the real environment"
---

# Read Config at Call Time, Not Import Time

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from snapshotting config into module-level constants at import time, where it freezes before the environment is fully loaded and becomes untestable.

**[Copy-paste ready version](../../install/read-config-at-call-time-not-import-time.md)** — just the instruction block, no explanation.

## The Problem

The AI writes `API_TIMEOUT = int(os.environ.get("API_TIMEOUT", "30"))` at the top of a module. It looks clean — a named constant, defined once, right where you'd expect. But that line executes the moment anything imports the module, which is often before `load_dotenv()` runs, before the test harness patches the environment, before the app framework finishes its bootstrap. The value is frozen from whatever the environment happened to contain at import time, and nothing that happens afterward can change it.

The symptoms are maddeningly indirect: tests that pass alone but fail in a suite depending on import order; `monkeypatch.setenv` that visibly sets the var yet changes nothing; a worker that ignores its env vars because a transitive import pulled the module in early. Nobody suspects the config line, because the config line looks perfect.

AI assistants default to this because module-level constants are the most common pattern in training data, and because the bug never fires in a quick single-file check. The import-order dependency only shows up when the module meets the rest of the system.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Read Config at Call Time, Not Import Time

NEVER read environment variables or config files in code that executes at module import — top-level statements, class-attribute defaults, decorator arguments, function parameter defaults. Import-time reads freeze a value before dotenv loading, test patching, or app bootstrap can run, and the resulting bugs depend on import order.

- Put config reads inside a function or a lazily-initialized config object: a `get_settings()` accessor, a cached factory, a config class instantiated during app startup — anything that executes after the environment is fully assembled.
- These are all import-time reads in disguise; avoid every one:
  - `TIMEOUT = int(os.environ["TIMEOUT"])` at module top level
  - `def fetch(url, timeout=settings.TIMEOUT)` — parameter defaults evaluate at definition time in many languages
  - `@retry(attempts=config.MAX_RETRIES)` — decorator args evaluate at import
  - class attributes initialized from `env` in the class body
- Caching is fine — read once at startup and reuse — as long as "once" happens inside the application's init path, not as a side effect of `import`.
- If the project already has a settings object or config accessor, route new values through it instead of adding fresh `os.environ` reads at module scope.
- In tests, the proof that you did this right: setting an env var before calling the function changes behavior, regardless of when the module was imported.

**Red flags that you're about to violate this:**
- "A module-level constant is cleaner than a function call."
- "This module is always imported after dotenv loads."
- "I'll read it once at the top so we don't pay the lookup cost."
- "The default parameter makes the signature self-documenting."
- "It works when I run this file directly."

---

## Why It Works

1. **It names the hidden execution time.** The AI sees `X = env(...)` as a declaration; pointing out that it's code running at import — before dotenv, before test patches — reclassifies it as a sequencing hazard.
2. **It enumerates the disguised variants.** Parameter defaults and decorator arguments are import-time reads that don't look like it; listing them blocks the workarounds the AI would otherwise reach for.
3. **It preserves the performance instinct legitimately** — cache at startup, not at import — so the AI isn't tempted to defend the top-level read as an optimization.
4. **The test criterion is mechanical:** set var, call function, behavior changes. That's checkable without understanding the whole bootstrap.

## Origin

A queue consumer read its batch size into a module-level constant. A refactor added an innocent import at the top of the entrypoint, which transitively imported the consumer module two lines before `load_dotenv()`. Every environment silently fell back to the hardcoded default batch size of 1, and throughput dropped 40x. The diff that caused it contained one new import statement and zero changed config lines, which is why it took two days to find.
