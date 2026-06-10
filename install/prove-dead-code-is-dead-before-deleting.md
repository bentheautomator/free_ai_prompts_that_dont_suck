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
