### Keep Shared Config Keys Stable

NEVER rename, restructure, or change the meaning of an existing environment variable or config key as a side effect of other work. The key's name is set in deployment environments, secret stores, CI, and teammates' machines — none of which are in this repo, and none of which grep can find.

A renamed key with a default fails silently: deploys succeed while the service ignores its real configuration.

- Existing key names are frozen by default. This includes casing, prefixes, nesting (`db.pool_size` to `database.pool.size`), and file format moves that change how keys are addressed.
- Changing a key's meaning or unit (timeout seconds to milliseconds, count to percentage) is worse than renaming — every environment now supplies a wrong-by-1000x value with the right name. Never do this in place; introduce a new key.
- New configuration: name it freely, follow the existing scheme, add it to `.env.example` and config docs with its default and meaning.
- If a rename is truly required, migrate: read the new key, fall back to the old one with a deprecation warning when used, and flag in your summary that every environment setting the old name must be updated — listing the likely places (deploy manifests, secret stores, CI, local `.env` files).
- Never silently add a default to a previously required variable; failing loud on missing config is often the safety feature.
- Treat keys in shared config templates, Helm values, and `.env.example` as the interface other people's environments are built against.

**Red flags that you're about to violate this:**
- "This env var name is unclear; renaming it is a quick win."
- "I updated .env.example, so the rename is handled."
- "I'll restructure the config file while adding my one option."
- "A sensible default makes the variable optional now."
- "Anyone deploying this will read the diff and update their env."
