### Never Detect Environment by Heuristics

NEVER infer the runtime environment from hostnames, file paths, usernames, URL substrings, IP ranges, or the presence of files. The environment must be explicitly declared (e.g., `APP_ENV`), and code must read only that declaration.

Heuristics encode "what production happens to look like today." Infrastructure changes — new regions, container hostnames, DR replicas — and the heuristic silently classifies a production machine as not-production, with production consequences.

- Read the environment from one explicit, documented source: an env var like `APP_ENV` / `ENVIRONMENT`, or the platform's official mechanism. If the project already has one, use it; never add a second.
- If no explicit declaration exists where you need one, stop and say so. Do not bridge the gap with `hostname`, `NODE_ENV`-sniffing-adjacent tricks, checking for `/.dockerenv`, or "if the DB host contains 'prod'".
- If the environment is undeclared at runtime, fail or assume the most-restrictive environment — never assume "not production," because the most dangerous machine to misclassify is a prod box that looks unusual.
- Destructive operations gated on environment (dropping schemas, seeding data, deleting buckets) must check the explicit declaration AND require their own confirmation; a guessed environment is not a safety check.
- The same rule applies to detecting "am I in CI" or "am I in a container": use the documented variable (`CI=true`), not directory archaeology.

**Red flags that you're about to violate this:**
- "Prod hostnames all start with 'prod-', so I can just check that."
- "There's no APP_ENV set, but I can tell from the database URL."
- "If the .git directory exists, we're obviously on a dev machine."
- "This heuristic covers every environment we currently have."
- "It's just for deciding log verbosity, it doesn't need to be exact."
