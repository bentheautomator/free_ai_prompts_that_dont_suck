---
title: Don't Make Everything Pluggable
slug: dont-make-everything-pluggable
category: architecture
tags: [universal, architecture, abstraction]
works_with: all
severity: medium
one_liner: "Plugin registries and strategy configs for decisions that never vary"
---

# Don't Make Everything Pluggable

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from building registries, plugin loaders, and config-selected strategies for behavior that has exactly one variant and no requirement to vary.

**[Copy-paste ready version](../../install/dont-make-everything-pluggable.md)** — just the instruction block, no explanation.

## The Problem

Asked to add CSV export, the AI ships an `ExporterRegistry`, a `register_exporter()` decorator, a config key `export.format`, and dynamic dispatch by string name — wrapped around the one CSV exporter anyone asked for. The feature works. It also turned a function call into a miniature framework: behavior is now selected at runtime from a string, "find the code that runs" requires tracing registration side effects, and there's a config option that has exactly one valid value, waiting to be set wrong.

This is a different disease from premature interfaces. The interface at least sits still; pluggability machinery is *active* — registries populated at import time, conditionals on config values, string-keyed lookups the type checker can't follow, plugin discovery that turns startup order into a correctness concern. Every behavior moved from code into configuration becomes invisible to static analysis and impossible to find with "go to definition." And configurable-but-never-configured options are a documented source of production incidents: the option's untested second value works right up until someone sets it.

AI assistants generate this machinery because frameworks in training data look like this, and because "extensible" reads as praise. The question that's never asked: is there a requirement — today, in this task — for the behavior to vary? Usually the answer is no, and hardcoding is not a compromise; it's the correct design.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Make Everything Pluggable

NEVER build pluggability machinery — registries, plugin loaders, hook systems, strategy selection from config, string-keyed dispatch tables — unless the current task contains at least two real variants or an explicit requirement for runtime selection. One behavior is a function call, written directly.

Every behavior moved from code into configuration trades type-checked, navigable, greppable control flow for runtime lookup — that's a real price, paid for flexibility that usually never gets used.

- One exporter is `export_csv(...)` called directly — no registry, no `format` config key, no `get_exporter("csv")`
- Two real variants in this task is a plain `if`/`match` or a dict of functions at the call site — visible, typed, all cases in one screen. Registries start earning their keep around variant four or five, or when variants live outside the core (actual plugins)
- Don't add config options for decisions nobody asked to configure: every knob is a code path that needs testing in all positions and an invitation for production to differ from every test
- Don't dispatch on strings when the variants are known at build time; the type checker can't tell `"csv"` from `"cvs"` and neither will the AI editing this code next year
- If the codebase already has a real registry with multiple registered implementations, register into it — this rule bans founding new empires, not following existing ones
- Asked explicitly for a plugin architecture? Build it. This rule is about inventing the requirement, not refusing it

**Red flags that you're about to violate this:**
- "A registry makes it trivial to add new formats later..."
- "I'll make it configurable so we don't have to touch code to change it..."
- "Hardcoding the choice feels inflexible..."
- "This is how the big frameworks structure it..."
- "It's just one config key and one lookup table..."
- "Future exporters can self-register, it's elegant..."

---

## Why It Works

1. **It demands variants, not visions.** "Two real variants in this task" is an evidence test; "we'll want more formats later" never has to survive contact with anything, which is why it always sounds true.

2. **It prices configuration honestly.** A config knob isn't free flexibility — it's an untested second code path plus a runtime failure mode; making that cost explicit changes the default.

3. **It maps machinery to scale.** Direct call → `if` → dict → registry is a ladder with thresholds; giving the AI the intermediate rungs removes the leap from "one case" straight to "framework."

4. **It keeps static analysis in the loop.** Build-time-known variants dispatched in code stay visible to the type checker, grep, and go-to-definition — the three tools every future maintainer, human or AI, actually uses.

## Origin

A payments team debugging a "webhook handler not firing" spent a day discovering that handlers self-registered via a decorator, registration happened at import, and a refactor had removed the one import that triggered it — no error, just silence. The registry served three handlers, all known at build time, all in the same package, registered three lines from each other. A dict literal would have made the bug a `KeyError` with a stack trace, or more likely impossible. The registry had been added, per the original PR description, "to make adding future handlers easy." Adding a handler to the dict would have been one line.
