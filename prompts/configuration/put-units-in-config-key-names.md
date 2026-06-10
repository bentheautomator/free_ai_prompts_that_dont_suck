---
title: Put Units in Config Key Names
slug: put-units-in-config-key-names
category: configuration
tags: [universal, config, naming]
works_with: all
severity: medium
one_liner: "Stops timeout: 30 ambiguity — thirty of what, exactly?"
---

# Put Units in Config Key Names

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from creating numeric config keys whose units live only in someone's memory — `timeout: 30`, `max_size: 100`, `interval: 5`.

**[Copy-paste ready version](../../install/put-units-in-config-key-names.md)** — just the instruction block, no explanation.

## The Problem

`timeout: 30`. Thirty what? The developer who wrote it knew (seconds, probably). The library underneath might disagree (milliseconds, often). The operator tuning it at 2am during an incident gets to guess, and a guess in the wrong direction is off by a factor of a thousand. The same ambiguity infects `cache_size: 512` (megabytes? entries?), `retry_delay: 2` (seconds? attempts use exponential what?), and `max_upload: 10` (MB? MiB? thousand bytes, if a marketing person configured it?).

AI assistants generate unitless keys because the surrounding code makes the unit obvious *to the code*: the value flows into `setTimeout(ms)` or `time.sleep(seconds)` two layers down, and the AI, holding the whole call chain in context, doesn't experience the ambiguity. The config file's reader has no call chain. They have a key, a number, and a deadline.

Worse, unitless keys invite unit *drift*: the underlying call changes from a seconds-based API to a milliseconds-based one during a refactor, the config key keeps its name and value, and `timeout: 30` quietly becomes thirty milliseconds. Nothing in the file changed; everything about its meaning did.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Put Units in Config Key Names

Every numeric config value with a dimension carries its unit in the key name: `timeout_seconds`, `cache_ttl_ms`, `max_body_bytes`, `retry_interval_ms`. NEVER create `timeout`, `delay`, `size`, or `limit` keys with bare numbers and an implied unit.

The unit lives in the name because the name is the only part of the config the operator can see. The code knows the unit; the person editing the YAML at 2am does not.

- New keys: bake the unit in — `_seconds`, `_ms`, `_bytes`, `_mb`, `_percent`, `_count`. If the value is a dimensionless count, say so: `max_retry_count`, not `max_retries: 3` next to `timeout: 3` where the eye reads them as siblings.
- Use the unit the underlying API actually consumes where reasonable, and convert exactly once at the config layer if not. The key's name must match the value's unit, not the internal representation after conversion.
- If the format supports duration/size strings (`30s`, `512MB`, Go durations, ISO-8601), prefer them — then the value itself carries the unit and the parser enforces it.
- When consuming an existing unitless key, don't guess from the value's magnitude ("30 is probably seconds"). Read the code that uses it, then add a comment at the key documenting the unit you confirmed.
- Renaming an existing unitless key to a united one is a config key rename: alias the old name during transition, don't break environments to improve a name.

**Red flags that you're about to violate this:**
- "The unit is obvious from context."
- "The docs explain that it's milliseconds."
- "Everyone on the team knows timeouts are in seconds here."
- "Adding _ms makes the key name clunky."
- "The value 30000 makes it clear it's milliseconds."

---

## Why It Works

1. **It puts the information where the reader is.** Code-side knowledge (the call chain) is invisible at the config file; the key name is the one channel guaranteed to reach the operator mid-incident.
2. **It pins the unit against refactors.** When the key is `timeout_seconds`, changing the underlying API to milliseconds forces a visible conversion or a visible rename — the silent reinterpretation path is closed.
3. **Wrong guesses are thousand-fold errors, not rounding errors.** Seconds-vs-milliseconds is three orders of magnitude; the cost asymmetry justifies the clunkier name everywhere, every time.

## Origin

During an outage, an engineer raised a struggling service's `request_timeout: 5` to `request_timeout: 30` to ride out downstream latency. The value was milliseconds — the service now timed out every request in 30ms, and the partial outage became a total one within a minute of the "fix." The original author confirmed afterward that the unit was documented: in a wiki page, two reorganizations ago. The key was renamed `request_timeout_ms` in the postmortem's first follow-up PR.
