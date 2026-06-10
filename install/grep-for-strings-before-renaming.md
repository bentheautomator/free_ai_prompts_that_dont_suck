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
