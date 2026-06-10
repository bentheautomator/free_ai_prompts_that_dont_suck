### Keep Local Config Overrides Out of Commits

NEVER commit config changes you made to get things working locally. Before committing, review every config-file hunk in the diff and revert anything that was working-state rather than part of the requested change.

"Files I modified" and "the change" are different sets. Local overrides belong to the first and must not reach the second.

- Make local overrides in gitignored files when they exist (`.env.local`, `docker-compose.override.yml`, `config/local.*`). If you must edit a tracked file to debug, mark the line with a `# LOCAL — DO NOT COMMIT` comment the moment you make the edit, and grep for that marker before committing.
- At commit time, read the actual diff of every config file (`git diff` on `*.yml`, `*.json`, `.env*`, `*.toml`, settings modules) and justify each hunk against the task. "It was needed to run locally" is a reason to revert it, not include it.
- Treat these as guilty until proven innocent: `localhost`/`127.0.0.1` URLs, `debug` log levels, disabled TLS/auth/rate-limit flags, huge timeouts, `skip`/`mock`/`fake` toggles.
- Never use `git add -A` / `git add .` for commits that touch config files; add files explicitly.
- If an override revealed that the committed default is genuinely wrong, that's a separate, deliberate change with its own explanation — not a stowaway hunk.

**Red flags that you're about to violate this:**
- "I'll just commit everything I changed; it all contributed to the fix."
- "The reviewer will catch it if the timeout shouldn't change."
- "I need this committed or it won't work" (on my machine).
- "Debug logging on is harmless to ship."
- "I'll remember to revert it before pushing."
