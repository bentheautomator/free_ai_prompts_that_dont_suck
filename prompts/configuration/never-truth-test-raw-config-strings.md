---
title: Never Truth-Test Raw Config Strings
slug: never-truth-test-raw-config-strings
category: configuration
tags: [universal, config, coercion]
works_with: all
severity: high
one_liner: "Stops if-checks on raw env strings where the string 'false' is truthy"
---

# Never Truth-Test Raw Config Strings

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from using raw config strings in boolean or numeric contexts, where `"false"` is truthy and `"0"` depends on the language.

**[Copy-paste ready version](../../install/never-truth-test-raw-config-strings.md)** — just the instruction block, no explanation.

## The Problem

Environment variables are strings. All of them, always. `DEBUG=false` puts the five-character string `"false"` into the process environment, and in Python, JavaScript, and Ruby, a non-empty string is truthy. So `if os.environ.get("DEBUG"):` enables debug mode when someone explicitly set it to false. The operator did exactly the right thing and got exactly the wrong behavior.

AI assistants write this constantly because the code reads correctly in English — "if debug, then..." — and because it works in the one case they mentally test (`DEBUG=true`). The failure case requires someone to set the variable to a falsy-looking string, which is precisely what operators do when they want to turn something off without deleting the line. The same trap catches numbers (`"0"` is truthy in Python and JS, falsy in PHP), and comparisons (`os.environ["MAX_RETRIES"] > 3` is comparing a string in some languages, a crash in others).

The resulting bugs are diabolical because the config file looks correct. Everyone debugging the incident reads `DEBUG=false`, nods, and looks elsewhere.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Truth-Test Raw Config Strings

NEVER use a raw config or environment value in a boolean, numeric, or comparison context. Parse it to a typed value first, at the config layer, exactly once.

Every env var is a string. `"false"`, `"0"`, `"no"`, and `"off"` are all non-empty strings, and non-empty strings are truthy in most languages. `if env.DEBUG:` turns debug on when an operator explicitly turned it off.

- Convert at the boundary: read the string, parse it into a real `bool`/`int`/`float`/`duration`, and pass only the typed value into application code. Application code should never see the raw string.
- Use the project's existing parsing helper if it has one (pydantic settings, `envconfig`, `Boolean.parseBoolean`-style utilities, a `parse_bool` in the config module). If there isn't one, write one helper and use it everywhere — don't inline `value == "true"` at each call site.
- Parsing must be strict: accept a defined set (`true/false`, `1/0`, case-insensitive), and treat anything else as a configuration error, not as false. `DEBUG=ture` should fail loudly, not silently disable debug.
- Numbers too: `int(os.environ["PORT"])` with an explicit error if it doesn't parse, never string comparison or implicit coercion.
- When you see existing code truth-testing a raw env string, treat it as a live bug worth flagging even if it's outside your task.

**Red flags that you're about to violate this:**
- "If the variable is set at all, they obviously want the feature on."
- "Nobody would set it to the string 'false'."
- "JavaScript will coerce the comparison correctly here."
- "I'll just check truthiness; it's only a debug flag."
- "Parsing feels like overkill for one variable."

---

## Why It Works

1. **It states the invariant the AI keeps forgetting — env vars are always strings —** at the moment of code generation, where the English reading of `if env.DEBUG` would otherwise win.
2. **Boundary parsing collapses the bug surface to one function.** With fifty inline truthiness checks you need fifty correct ones; with one parser you need one.
3. **Strict parsing converts typos into startup errors.** Lenient parsing ("anything not 'true' is false") turns `ture`, `True ` with a trailing space, and `yes` into silent feature-offs that no log line will ever explain.

## Origin

A data pipeline had `DRY_RUN` guarding its delete phase. An operator ran a production cleanup with `DRY_RUN=false` set in the job spec, exactly as the runbook said. The check was `if os.environ.get("DRY_RUN"):` — the string `"false"` was truthy, dry-run mode engaged, and the cleanup silently deleted nothing for six weeks while storage costs climbed. The inverse incident, where `"false"` keeps a safety check truthy until someone unsets the var entirely and the real deletes run unrehearsed, is how this prompt earned its severity rating.
