---
title: Grep for Strings Before Renaming
slug: grep-for-strings-before-renaming
category: refactoring
tags: [universal, refactoring, naming]
works_with: all
severity: high
one_liner: "Stops renames that miss string-based references no compiler can see"
---

# Grep for Strings Before Renaming

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from renaming a symbol while missing the places that reference it as a string: configs, templates, reflection, CLI registrations, and docs.

**[Copy-paste ready version](../../install/grep-for-strings-before-renaming.md)** — just the instruction block, no explanation.

## The Problem

Static references to a symbol are the easy half of a rename. The hard half is everywhere the name appears as *text*: the YAML config that names a handler class, the Django template calling `{{ user.get_display_name }}`, the `getattr(obj, "process_refund")` dispatch, the cron entry invoking `manage.py rebuild_index`, the Terraform variable, the dashboard query, the onboarding doc. An assistant that renames the symbol and updates every import has still only done the part a compiler could have policed, and the string half fails at runtime, or worse, at deploy time, or worst of all, only in the one environment whose config nobody regenerated.

Models miss these because string references don't participate in the syntax of the language. Nothing about `"process_refund"` in a config file looks like a call site; it's just a string that happens to spell doom. The model's mental model of "references" is the language server's model, and the language server is blind here too.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Grep for Strings Before Renaming

Before renaming any symbol, ALWAYS search the entire repository for the name as a plain string, not just as a code reference. Renames break at runtime through references no compiler tracks.

If a name can be spelled in quotes, in config, or in a template, the type checker's approval means nothing.

- Run a repo-wide text search for the old name (and its common case variants: snake_case, camelCase, kebab-case) across ALL file types: YAML/JSON/TOML configs, env files, templates (HTML, Jinja, ERB), SQL, shell scripts, CI pipelines, Dockerfiles, infrastructure code, docs, and READMEs.
- In code, search for the name inside quotes: `getattr`/`setattr`, `send`/`__send__`, `importlib`/dynamic `import()`, mock patch targets, signal/event names, route names, serializer `fields = [...]` lists, admin and form `Meta` declarations, and string-keyed dispatch dicts.
- Framework magic counts: template engines, DI containers, ORM string lookups (`"author__name"`), task-queue task names, and management-command names all resolve symbols from strings at runtime.
- Every string hit gets one of three dispositions, stated explicitly: updated to the new name, confirmed to be an unrelated coincidence, or flagged because it lives outside the repo's control (external cron, saved dashboard, customer config) and the user must decide.
- That third category is a stop sign: if the name is referenced from systems you can't edit, the rename may need an alias or shouldn't happen. Ask.
- After the rename, run the same text search again. Explain any survivor or eliminate it.

**Red flags that you're about to violate this:**

- "My editor's rename-symbol handled all the references."
- "The type checker passes, so the rename is complete."
- "Config files wouldn't reference an internal function name."
- "Templates are presentation; they don't depend on method names."
- "A grep would mostly return false positives, so I'll skip it."

---

## Why It Works

1. **It separates the two halves of a rename.** The model equates "references" with what a language server sees; the rule defines the string half as a distinct, mandatory search with its own pass criteria.
2. **The three-disposition triage prevents both failure modes of grepping.** Without it, models either ignore string hits (missed references) or blindly rewrite them (corrupting coincidental matches). Forcing an explicit disposition per hit handles both.
3. **The outside-the-repo category converts unknowns into questions.** Saved dashboards and external crons are unfixable from inside the diff; routing them to the user is the only correct move, and the rule makes it the default instead of an afterthought.

## Origin

A cleanup renamed a task function `sync_inventory` to `synchronize_stock_levels`, with every import and call site updated and tests green. The task queue resolved workers by string name, and three scheduled jobs in a YAML file still said `sync_inventory`. The scheduler logged "unknown task" at a log level nobody watched, and inventory quietly stopped syncing for four days, surfacing as a wave of oversold items the following weekend.
