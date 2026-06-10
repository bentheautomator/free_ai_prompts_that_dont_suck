### Never Load Example Config as Live Config

NEVER make application code read an example or template config file (`.env.example`, `config.sample.yml`, `settings.dist.php`, `*.template`). These files are documentation for humans to copy — the moment code loads one, its placeholders become live values.

An app that won't boot without real config is correct. An app that boots on placeholders is a delayed incident.

- No fallback chains that end at a template: `config.yml, else config.example.yml` turns "deployment forgot the config" into "production runs on `changeme`."
- Don't auto-copy templates into place in Dockerfiles, entrypoints, setup scripts, or CI. Copying is a human act that comes with filling in values; automated copying ships the placeholders.
- A missing-config error is a feature. The fix is to provision real config (or tell the user to), not to widen the search path until something loads.
- Don't point tests at example files — tests should construct their own config or use dedicated fixtures, so the example stays a pure template and tests validate real shapes.
- Setup tooling may *detect* a missing config and print "copy config.example.yml to config.yml and edit it" — instruct, don't perform.
- If you edit an example file expecting behavior to change, stop: nothing reads it (and nothing should). Find the live config instead.

**Red flags that you're about to violate this:**
- "Falling back to the example file makes the app work out of the box."
- "The setup script can copy the template automatically to save a step."
- "The example values are reasonable defaults anyway."
- "Tests can just load config.example.yml, it has all the keys."
- "The boot error says config.yml is missing — easiest fix is to load what exists."
