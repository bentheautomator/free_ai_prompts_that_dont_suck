---
title: Prove Dead Code Is Dead Before Deleting
slug: prove-dead-code-is-dead-before-deleting
category: legacy-code
tags: [universal, legacy]
works_with: all
severity: high
one_liner: "Stops deletion of code that looks unused but is invoked in ways grep misses"
---

# Prove Dead Code Is Dead Before Deleting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting code that pattern-matches as dead but is actually invoked through reflection, configuration, cron, or callers outside the repo.

**[Copy-paste ready version](../../install/prove-dead-code-is-dead-before-deleting.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant scans the codebase, finds a function with no callers in the files it can see, and deletes it as cleanup. The function was invoked by name from a YAML config, dispatched via reflection, called by a cron job defined in infrastructure code, or imported by a sibling repository the AI has never read. The deletion compiles clean, tests pass, and the failure surfaces three days later as a stack trace in a scheduled job nobody watches.

The structural issue is that "no callers found" and "no callers exist" are different claims, and the AI only has evidence for the first. Static reachability analysis works inside a single statically-typed module; it falls apart at every dynamic boundary — string-based dispatch, dependency injection containers, plugin registries, template engines, serialization hooks, ORM lifecycle callbacks, and anything that lives in another repo entirely.

AI assistants delete aggressively because unused code reads as a defect to fix, and deletion is the most satisfying diff there is: pure red, zero risk visible in the diff itself. The risk lives precisely in what the diff cannot show.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Prove Dead Code Is Dead Before Deleting

NEVER delete code because you found no callers. Absence of references in the files you searched is not evidence of death; it is evidence of the limits of your search. Code that looks orphaned is routinely invoked through dynamic dispatch, configuration, schedulers, or other repositories.

Before deleting anything, you must:

- Search for the symbol's name as a *string*, not just as a code reference: config files (YAML, JSON, TOML), templates, SQL, environment variables, infra-as-code, CI pipelines, and documentation.
- Check for dynamic invocation in the codebase's idiom: reflection, `getattr`/`send`/`Invoke`, DI container registrations, plugin or handler registries, route tables, serializer hooks, ORM callbacks.
- Run `git log` on the file. Recent commits touching "dead" code mean someone disagrees with you about its deadness.
- Ask whether external consumers exist: other repos, scheduled jobs, ops scripts, partner integrations. If you cannot verify, say so and let the user decide.
- If the user did not ask for the deletion, propose it instead of doing it, and state exactly what evidence you gathered and what you could not check.

Exported symbols, public functions, HTTP handlers, CLI subcommands, and anything with `handler`, `hook`, `job`, `task`, or `callback` in its name get extra suspicion: these are *designed* to be called from places you cannot see.

**Red flags that you're about to violate this:**
- "Grep found zero callers, so this is safe to remove."
- "It's not referenced anywhere in the project."
- "The IDE marks it as unused."
- "Dead code is tech debt; removing it is always an improvement."
- "If something breaks, the tests will catch it."
- "Nobody could possibly be calling this old thing."

---

## Why It Works

1. **It reclassifies the evidence.** "No callers found" gets demoted from a conclusion to a search result, which forces the follow-up question: what couldn't the search see?
2. **It enumerates the invisible call sites** — config, reflection, cron, sibling repos — so the AI checks the specific places dynamic invocation hides instead of vaguely "being careful."
3. **String search is the cheap trick that catches most of it.** Dynamic dispatch almost always involves the symbol's name appearing as text somewhere; searching for the name as data instead of code finds what reference analysis misses.
4. **It makes uncertainty reportable instead of resolvable-by-deletion.** The AI is allowed to say "I can't verify external callers," which is the honest state, rather than treating unverifiable as unused.

## Origin

During a cleanup pass, an assistant removed an "unused" exporter class with no in-repo callers. The class was instantiated by name from a job-scheduler config file in a separate infrastructure repo, and the nightly regulatory export silently stopped producing files. The gap was noticed eleven days later by the recipient, not the team, and the backfill took longer than the original feature had taken to build.
