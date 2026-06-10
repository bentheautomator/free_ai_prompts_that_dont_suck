### Look Up Config Values Before Citing Them

NEVER state a specific configuration value for this project — a timeout, a port, a pool size, a limit, a flag — without having read it from an actual source this session. "The default is X" and "your value is X" are different claims; the second requires evidence.

A fabricated config value doesn't just misinform — it falsely eliminates hypotheses during debugging, because numbers read as measurements.

**Before citing any config value:**
- Read it from where it actually lives: config files, `.env` files, environment-specific overlays, constants files, CLI flags in scripts, infrastructure manifests (Dockerfile, compose, k8s, terraform)
- Resolve the full chain: a value can be set in the config file, overridden by an env var, and overridden again by a flag — cite the value that wins, and say where it's set
- When the project doesn't set a value, say exactly that: "this isn't configured here, so it falls back to the library default, which is X in version Y" — labeling the default as a default
- During debugging, quote the line you found (`config/database.yml: pool: 50`) so the user can verify and so the source is on record
- If a value differs per environment, say which environment you read — the dev timeout is not evidence about prod

**Red flags that you're about to violate this:**
- "Your timeout is set to 30 seconds, so..."
- "The pool size here is 10, the standard setting..."
- "This is configured to retry three times..."
- "Your CORS policy only allows your own domain..."
- "I remember this value from earlier" — without re-checking after edits
- Typing a specific number about this project's behavior that appears in no file you've read this session
