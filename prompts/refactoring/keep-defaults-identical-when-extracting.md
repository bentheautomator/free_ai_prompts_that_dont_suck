---
title: Keep Defaults Identical When Extracting
slug: keep-defaults-identical-when-extracting
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: high
one_liner: "Stops extractions that silently change default values, timeouts, and limits"
---

# Keep Defaults Identical When Extracting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from changing effective default values (timeouts, retries, batch sizes, flags) while extracting parameters, constants, or config.

**[Copy-paste ready version](../../install/keep-defaults-identical-when-extracting.md)** — just the instruction block, no explanation.

## The Problem

Extracting hardcoded values into parameters and config is bread-and-butter refactoring, and it has a signature failure: the value changes in transit. The literal `timeout=45` becomes a parameter with `default=30`, because 30 is what timeouts usually are in the model's training data. A hardcoded batch size of 500 becomes `BATCH_SIZE = 100` because round numbers gravitate to other round numbers. A `retries=5` buried in a call becomes an option that defaults to 3. The function signature now advertises configurability, the diff looks like pure structure, and every existing caller that passed nothing just got different behavior.

This happens because extraction requires the model to write the value twice (once removing the literal, once choosing the default), and the second write is generation, not copying. Generation regresses to the typical. The original value was usually atypical *on purpose*: that 45-second timeout exists because the vendor's slow endpoint needs it, and "typical" is precisely wrong.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Defaults Identical When Extracting

When extracting a hardcoded value into a parameter, constant, or config entry, the effective value for all existing callers MUST remain exactly what it was. NEVER normalize a value to something more typical while moving it.

Extraction means relocating a value, not re-deciding it. The original number was usually tuned to something real.

- The default of a new parameter is the literal it replaced, verbatim: `timeout=45` extracts to `timeout: int = 45`, not `= 30`. Same for retries, batch sizes, buffer lengths, ports, limits, sleep durations, and booleans.
- When several call sites used *different* literals, there is no single safe default. Either pass the value explicitly at each site (preserving each one) or stop and ask which should win; never pick the most common and silently change the rest.
- Extracting to config means the config's default (and every environment's config file you control) yields the old value. A new config key whose absence falls back to a different number is a behavior change in disguise.
- Copy values exactly, including units and type: `30` seconds is not `30000` anywhere milliseconds are expected, `0.5` is not `1`, and `None` is not `0`. Recheck every unit boundary you cross.
- Flag defaults are behavior: a hardcoded `verify=True` extracts to `verify: bool = True`. Defaulting it to `False` "for flexibility" is a security change, not a refactor.
- After extracting, diff the effective values: list each call site with its before and after value. Every row must match.

**Red flags that you're about to violate this:**

- "30 seconds is the standard timeout, so that's a sensible default."
- "I'll round this odd value to something cleaner while I'm extracting it."
- "Most callers use 100, so 100 becomes the default."
- "The default doesn't matter much; callers can override it."
- "I'll make the new flag default to false to be safe."

---

## Why It Works

1. **It names the copy-vs-generate gap.** The model believes it's moving a value when it's actually re-emitting one, and re-emission regresses to the typical; making that mechanism explicit turns "extract" into a copying task with a verification step.
2. **It removes discretion at the exact decision point.** "The default is the literal it replaced, verbatim" leaves no slot where judgment, and therefore drift, can enter.
3. **The multiple-literals rule blocks the silent majority vote.** Picking the most common value and converting the outliers is the subtle variant of this failure; requiring per-site preservation or a question closes it.
4. **The before/after value table catches what code review misses.** A changed default hides inside a structurally noisy diff; a two-column table of effective values makes it a one-glance check.

## Origin

While extracting HTTP settings into a config object, an assistant turned a hardcoded `timeout=120` on a report-generation call into a `timeout` option defaulting to 30, matching the other endpoints. Reports longer than thirty seconds, which was most of the useful ones, began failing with timeout errors. The change was found two days later by diffing the config object against the original literals line by line, a comparison that took five minutes and would have taken zero if done before merging.
