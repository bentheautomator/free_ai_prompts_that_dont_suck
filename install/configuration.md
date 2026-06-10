### Alias Old Config Keys When Renaming

NEVER rename a config key as a clean break. The old name is set in environments you cannot see or edit from this repo; a rename without an alias orphans all of them at once.

Code renames are atomic. Config renames are migrations.

- Don't rename config keys at all unless the task asks for it. "Better name" is not worth a multi-environment migration; if you think a rename is warranted, propose it separately.
- When a rename is genuinely needed, read both names for at least one full release cycle: prefer the new key, fall back to the old one, and log a deprecation warning when the fallback fires (`"DB_CONN is deprecated, use DATABASE_URL"`).
- If both names are set and disagree, that's a configuration error — fail loudly rather than silently picking one.
- Update every in-repo enumeration in the same change: `.env.example`, compose files, Helm values, docs, test fixtures.
- List the out-of-repo places that need updating (environment dashboards, secret stores, sibling repos) in the change description, because the person merging this can't grep for them.
- Removing the old-name fallback later is its own change, made after confirming the deprecation warning has gone quiet in every environment.

**Red flags that you're about to violate this:**
- "I renamed it everywhere" (everywhere meaning: in this repo).
- "The new name is clearer, so I updated it while I was in there."
- "Whoever deploys will see the example file changed."
- "Supporting both names is messy; a clean cut is simpler."
- "It's just a rename, nothing about the behavior changed."

### Decide What Empty Env Vars Mean

Every env var read must deliberately handle three states — unset, empty, set — and the project must handle them ONE way. NEVER let the choice between `||` and `??`, or between `in os.environ` and `os.environ.get(...)`, silently make that decision per call site.

`FOO=` is set and empty. Compose files, CI interpolation, and templating produce that state routinely; code that only imagines two states hands `""` to something that needed a URL.

- Default policy, unless a key documents otherwise: empty means unset. Strip whitespace; if nothing remains, behave exactly as if the variable were absent (apply the default, or fail if required). This matches how empties are produced — by accident.
- Required-var validation must reject empty, not just absent. `if not os.environ.get("DATABASE_URL"):` is correct; `if "DATABASE_URL" not in os.environ:` waves `DATABASE_URL=` straight through to the connection code.
- If a key gives empty a real meaning ("empty CORS_ORIGINS = allow none"), that's an exception: document it at the key's declaration, and prefer an explicit sentinel (`CORS_ORIGINS=none`) over load-bearing emptiness.
- Implement the policy once, in the config layer's read helper — not re-decided by each call site's choice of `||` vs `??`. In JS specifically, treat a bare `??` on `process.env` as a flag: it asserts that empty string is a meaningful value. Is it?
- Extend the same three-state thinking to file-based config: a key present with `null`/`""` versus a key absent. Loaders that collapse those differently than your env handling create the same bug one format over.

**Red flags that you're about to violate this:**
- "I checked that the variable is set, so it has a value."
- "Nobody sets a variable to empty on purpose." (Correct — that's why it happens by accident.)
- "`??` and `||` do basically the same thing here."
- "The empty string will just fail validation downstream anyway."
- "Compose always passes our variables through, the value will be there."

### Declare Defaults at the Config Layer

ALWAYS declare default values in the project's config layer — the settings module, schema, or config file — never inline at the point of use. Application code reads config values; it does not invent fallbacks for them.

An inline default is a configuration decision hidden where no operator, reviewer, or future maintainer will look. Two inline defaults for the same key is a bug generator.

- `os.environ.get("X", "fallback")`, `config.get("x", 5)`, `process.env.X ?? "10"`, and `value || default` in business logic are all the same smell. Move the default to where the config is declared and have the call site read the resolved value.
- The config layer means: the settings class/schema (pydantic `Field(default=...)`, a `defaults.yml`, the central `config.ts`), where every key, its type, and its default are visible in one place.
- One key, one default. If a key is read in multiple places, none of them get their own fallback — they all see the value the config layer resolved.
- Defaults declared at the config layer must also appear in the example/template file, so the documented surface matches the real one.
- If you're adding a read for a new key, that's the moment to declare it properly: name, type, default, and a one-line description, in the config layer, in the same change.
- Magic numbers that are really tunables (batch sizes, intervals, limits) follow the same rule: promote them to declared config with a default, don't leave them as literals with aspirations.

**Red flags that you're about to violate this:**
- "The fallback is right here at the call site, which is self-documenting."
- "It's a sensible default, it doesn't need to be configurable-looking."
- "Touching the config module is out of scope for this fix."
- "Another file already reads this key with its own default; I'll match that pattern."
- "It's just `|| 10`, hardly configuration."

### Deprecate Config Keys Before Deleting Them

NEVER delete a config key from a shared location just because this repo no longer reads it. A key in a shared store (ConfigMap, shared env file, values file, config service) has consumers you cannot grep for: other repos, sidecars, cron jobs, scripts, runbooks, humans.

Code deletion fails your build. Config deletion fails someone else's runtime.

- Distinguish scope before deleting. A key in this repo's own config, read only by this repo's code: deletable with the code. A key in anything shared or deployed where other processes can read it: deprecation process, not deletion.
- Deprecation process: mark the key deprecated (comment with date and replacement), announce it in the change description with a removal date, keep its value flowing in the meantime, and remove it in a later, dedicated change after the window passes.
- "No usages found" must state its search scope. If you searched one repo, say "no usages in this repo" — and treat that as insufficient for shared keys. Search sibling repos, infra repos, and runbooks if you can; name the ones you couldn't.
- Removing the value while keeping the key (setting it empty) is deletion with worse error messages. Don't.
- Stopping the *production* of a value others consume (the job that writes a config entry, the export that populates it) is the same failure mode as deleting the key. Same process.
- If the key holds something dangerous-to-keep (a decommissioned endpoint that now points somewhere wrong), say so explicitly and make the removal a coordinated change, not a cleanup commit.

**Red flags that you're about to violate this:**
- "Grep shows nothing reads this anymore."
- "I removed the code that used it, so removing the key is part of the same cleanup."
- "If something else needed it, that would be documented somewhere."
- "Leaving unused keys around is clutter; better to delete now."
- "Worst case, whoever needs it can re-add it."

### Derive Environment Configs From a Base

Per-environment config files must contain ONLY the values that genuinely differ for that environment, layered over a shared base. NEVER maintain full parallel copies of the configuration per environment, and NEVER create a new environment by duplicating an existing one's full file.

Identical keys duplicated per environment is drift with a delay timer: every shared-value change becomes an N-file edit that someone will eventually do in N-1 files.

- Use whatever layering the stack supports: `base.yml` + `production.yml` overlay, `application.yml` with profile overrides, Kustomize bases, shared defaults imported by env files. If the project already layers, respect the layering — add common values to the base, not to each environment.
- A value identical across all environments belongs in the base. Period. If you're about to paste the same key into three files, you're putting it in the wrong place.
- A value in an environment overlay should make a reader ask "why is this different here?" — and the answer should be obvious or commented. Overlays are for differences, and differences are claims.
- When you find existing duplication (same key, same value, three files), flag it; consolidating to base is usually cheap and always worth mentioning.
- If true layering doesn't exist and can't be added now, simulate the discipline: make every multi-environment edit to all files in one change, and say explicitly which files you touched.
- New environment = new minimal overlay over the base, never a copy of staging's file with the names changed.

**Red flags that you're about to violate this:**
- "I'll add the key to production.yml later once it's tested in dev."
- "Copying staging.yml is the fastest way to set up the new environment."
- "The files are mostly the same, keeping them in sync by hand is fine."
- "I don't want to touch the base file, the overlay is safer."
- "This value is the same everywhere, but each file having it is more explicit."

### Don't Branch Defaults on Environment

A default is ONE static value, identical in every environment. NEVER compute a default from the environment name, another config value, or runtime conditions — `default = (env == "production") ? X : Y` makes the unset key mean different things in different places, recorded nowhere.

If environments need different values, they set the key explicitly in their own config. The difference belongs in config files (visible, diffable), not in fallback logic (invisible, evaluated).

- Pick the default for safety, not convenience: the value you'd want a brand-new, unconfigured environment to get. Each environment that wants otherwise overrides it in writing.
- `?? (APP_ENV === "production" ? a : b)`, defaults derived from `NODE_ENV`, "smart" defaults that sniff other settings (`debug ? verbose : quiet`), and defaults that differ between the config class and a per-env subclass are all the same pattern. Replace each with one static default plus explicit per-environment entries.
- The static default should appear in the example/template file, so unset-key behavior is documented behavior.
- If you can't choose a single safe default because environments genuinely disagree and no value is safe everywhere, that's not a default — make the key required and let every environment state its value.
- Framework dual-personality defaults you can't remove (dev servers that auto-enable debug): pin the value explicitly in config anyway, so your environments don't depend on the framework's mood.

**Red flags that you're about to violate this:**
- "Defaulting based on the environment gives everyone the right behavior automatically."
- "Devs shouldn't have to set this key just to get sensible local behavior."
- "The conditional default means less per-environment config to maintain."
- "It's documented — the ternary is right there in the code."
- "Production will override it anyway, the smart default is just a safety net."

### Don't Fix Local Problems in Shared Config

NEVER modify committed, shared configuration to solve a problem specific to the current machine. Shared config encodes the team's agreement; a local conflict is your problem to absorb locally, not theirs to inherit.

A port collision, a missing local service, or a path that doesn't exist on this machine is a local condition. Fixing it in a committed file exports your environment's quirks to every other environment.

- First ask: would this change be wrong on a teammate's machine or in CI? If yes, it doesn't belong in a committed file.
- Use the project's local-override mechanism instead: `.env.local`, `docker-compose.override.yml`, `config/local.*`, `settings_local.py`, direnv — whatever the project already supports. These exist precisely for this.
- If no override mechanism exists, propose adding one (gitignored) rather than editing the shared file.
- Environment variables that the shared config already reads (`PORT=5433 make dev`) are a fine zero-footprint fix.
- If you genuinely believe the shared default is wrong for everyone, say so explicitly and make that case in the change description — as a deliberate team-wide decision, not a drive-by fix.
- This applies to tool config too: editor settings, linter paths, test runner ports, registry mirrors.

**Red flags that you're about to violate this:**
- "The port was already in use, so I changed it in the compose file."
- "It works now" (on this machine, which is the only one I checked).
- "Everyone probably has the same conflict anyway."
- "It's a tiny config change, easy to revert if anyone complains."
- "I'll mention it in the commit message so people can adjust."

### Fail Fast on Missing Required Config

NEVER give a required config value a fallback default. If the application cannot function correctly without a value, its absence must crash the process at startup with a message naming the missing key. A silent fallback converts a loud deploy failure into a quiet production bug.

- Required values — connection strings, API endpoints, credentials references, bucket names, anything pointing at an external system — get read with no default: `os.environ["PAYMENT_API_URL"]`, `mustGetenv("PAYMENT_API_URL")`, or an explicit check that raises with the key name in the error.
- Optional values may have defaults, but only values where the default is correct in *every* environment (e.g., `LOG_FORMAT=json`). "Correct on my machine" does not qualify.
- NEVER default a required value to localhost, `127.0.0.1`, an empty string, a test endpoint, or a sandbox URL. Those are the defaults that silently route production traffic to the wrong place.
- If you genuinely need a dev convenience, put it in `.env.example` or a dev compose file — in the environment, not in the code path every environment shares.
- When you find existing code defaulting a required value, flag it rather than imitating the pattern.
- Error messages must name the key: `Missing required config: PAYMENT_API_URL`. "Configuration error" sends on-call spelunking.

**Red flags that you're about to violate this:**
- "I'll add a default so it works out of the box."
- "Defaulting to localhost is fine, that's just for dev."
- "An empty string is a safe fallback here."
- "Crashing on a missing var feels fragile; better to degrade gracefully."
- "Everyone will obviously set this in production."
- "The other config reads in this file use `.get()` with defaults, so I'll match."

### Give Every Feature Flag an Expiry

NEVER add a feature flag without a written removal condition, and NEVER preserve a flag that has met one. Flags are scaffolding, not architecture.

A flag at 100% (or 0%) for months isn't configuration — it's two codebases pretending to be one.

- When adding a flag, record its exit criteria where flags are declared: a comment or metadata field with owner, purpose, and removal condition ("remove after checkout v2 is at 100% for two weeks").
- Default new flags to temporary. If someone wants a permanent operational toggle (kill switch, tenant entitlement), that's a deliberate, labeled exception — say so explicitly.
- When you touch code guarded by a flag that is clearly settled (hardcoded on, 100% everywhere, off-branch unreferenced for months), propose deleting the flag and the dead branch as part of the change, not preserving both sides.
- When removing a flag, remove all of it: the declaration, the config entries in every environment, both code branches, and the tests that only exercised the dead branch.
- Don't write new logic inside a dead flag's off-branch. If you're not sure a flag is dead, ask; don't split the difference by updating both branches.

**Red flags that you're about to violate this:**
- "I'll keep both branches just in case someone flips it back."
- "Removing the flag is out of scope for this ticket."
- "It's safer to leave it — it's only a config entry."
- "I'll add the flag now and we can decide the rollout plan later."
- "The off-branch still compiles, so it's fine to keep maintaining it."

### Keep Environment Conditionals Out of Business Logic

NEVER branch on the environment name (`if env == "production"`) inside application code. Express the difference as a named config value — a capability — and let per-environment config set it. Business logic asks `config.email_sending_enabled`, never `env == "prod"`.

Scattered env-name checks turn "what does staging do?" into a grep-and-simulate exercise, and every new environment mis-sorts through all of them simultaneously.

- When you're about to write an environment check in app code, name the behavior it controls instead: `send_real_emails`, `payments_live_mode`, `strict_cors`. Add that key to the config layer, set it appropriately per environment, and branch on the key.
- The environment name should be consumed in approximately one place: the config loader that selects which value-set to apply. If `APP_ENV` is read anywhere else, that's the smell.
- Don't enumerate environments in logic (`env in ["staging", "production"]`) — the list is stale the day someone adds an environment, and it fails silently for the new one.
- When working in code that already has env conditionals, don't add siblings. Match the task's scope: introduce the capability key for your change, and flag the neighbors for conversion.
- Capabilities also make the safety default explicit: a new environment with no config gets the key's declared default (choose the safe one), instead of whatever side of a string comparison it happens to land on.

**Red flags that you're about to violate this:**
- "It's just one if-statement, a config key is ceremony."
- "This behavior is inherently about production, checking the name is honest."
- "There are already env checks in this file, I'm being consistent."
- "We only have three environments, the enumeration is fine."
- "I'll check `env != 'development'` so it's safe everywhere else."

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

### Never Truth-Test Raw Config Strings

NEVER use a raw config or environment value in a boolean, numeric, or comparison context. Parse it to a typed value first, at the config layer, exactly once.

Every env var is a string. `"false"`, `"0"`, `"no"`, and `"off"` are all non-empty strings, and non-empty strings are truthy in most languages. `if env.DEBUG:` turns debug on when an operator explicitly turned it off.

- Convert at the boundary: read the string, parse it into a real `bool`/`int`/`float`/`duration`, and pass only the typed value into application code. Application code should never see the raw string.
- Use the project's existing parsing helper if it has one (pydantic settings, `envconfig`, `Boolean.parseBoolean`-style utilities, a `parse_bool` in the config module). If there isn't one, write one helper and use it everywhere — don't inline `value == "true"` at each call site.
- Parsing must be strict: accept a defined set (`true/false`, `1/0`, case-insensitive), and treat anything else as a configuration error, not as false. `DEBUG=ture` should fail loudly, not silently disable debug.
- Numbers too: `int(os.environ["PORT"])` with an explicit error if it doesn't parse, never string comparison or implicit coercion.
- When you see existing code truth-testing a raw env string, treat it as a live bug worth flagging even if it's outside your task.

**Red flags that you're about to violate this:**
- "If the variable is set at all, they obviously want the feature on."
- "Nobody would set it to the string 'false'."
- "JavaScript will coerce the comparison correctly here."
- "I'll just check truthiness; it's only a debug flag."
- "Parsing feels like overkill for one variable."

### No Machine-Specific Values in Committed Config

NEVER commit a config value that encodes facts about the current machine: absolute paths under a home directory, locally-chosen ports, `*.local` hostnames, usernames, or paths to locally-installed tool versions.

A value that's correct here and meaningless everywhere else doesn't belong in a file everyone shares.

- Paths in committed config must be relative to the project root, or built from a variable (`$HOME`, `${workspaceFolder}`, `%APPDATA%`) — never `/Users/<name>/...` or `C:\Users\<name>\...`.
- Tool locations should be resolved, not pinned: `python3` via PATH, not `/opt/homebrew/bin/python3.11`; if a specific version matters, declare the version requirement (`.tool-versions`, `engines`), not the install path.
- If a value legitimately varies per machine (port, local DB host, browser binary), it belongs in the gitignored local layer (`.env.local`, `*.local.json`, override files) with a portable default in the shared file.
- Hostnames in shared config must be resolvable from every environment that reads them — `localhost` and service names from compose/k8s qualify; `daves-laptop.local` does not.
- Before committing any config change, scan the diff for your own username, home directory, or hostname. Finding one means a value took the wrong exit.

**Red flags that you're about to violate this:**
- "I used the absolute path so there's no ambiguity."
- "I verified this path exists, so the config is correct."
- "The port had to change locally, and committed config is where ports live."
- "Everyone here uses macOS anyway."
- "CI doesn't run this config, so portability doesn't matter."

### Parse Boolean Env Vars One Way

ALWAYS parse boolean config through the project's single shared helper. NEVER inline a fresh `=== "true"`, `!== "false"`, `in ("1", "yes")`, or truthiness check at a call site.

Multiple parsers means one env value can be true and false in the same process. That bug is invisible in any single file because every file is individually correct.

- Before parsing a boolean env var, find how the project already does it. If a helper exists (`parseBool`, `env_flag`, `strtobool` wrapper, the settings library's bool field), use it — even if you'd have written it differently.
- If no helper exists, create one and route the new code through it. One function, one definition of true: accept a small documented set case-insensitively (`true/false`, `1/0`), reject everything else loudly. `FLAG=ture` is an error, not a false.
- `!== "false"` deserves special hostility: it makes the *unset* variable true, so the flag defaults on and can never be safely introduced. Default values belong in the config layer, not encoded in comparison direction.
- When your change touches a file containing a divergent inline parser, flag it; migrate it if it's in scope.
- The helper, not each caller, decides the unset behavior: unset means "use the declared default," never "whatever this comparison happens to yield."

**Red flags that you're about to violate this:**
- "It's a one-line check, importing a helper is overkill."
- "This is how the file I'm editing already does it." (Is it how the *project* does it?)
- "Everyone sets booleans as 'true' or 'false', edge cases won't happen."
- "I'll use `!== 'false'` so it defaults to enabled."
- "Python's `bool()` on the string is close enough."

### Put Units in Config Key Names

Every numeric config value with a dimension carries its unit in the key name: `timeout_seconds`, `cache_ttl_ms`, `max_body_bytes`, `retry_interval_ms`. NEVER create `timeout`, `delay`, `size`, or `limit` keys with bare numbers and an implied unit.

The unit lives in the name because the name is the only part of the config the operator can see. The code knows the unit; the person editing the YAML at 2am does not.

- New keys: bake the unit in — `_seconds`, `_ms`, `_bytes`, `_mb`, `_percent`, `_count`. If the value is a dimensionless count, say so: `max_retry_count`, not `max_retries: 3` next to `timeout: 3` where the eye reads them as siblings.
- Use the unit the underlying API actually consumes where reasonable, and convert exactly once at the config layer if not. The key's name must match the value's unit, not the internal representation after conversion.
- If the format supports duration/size strings (`30s`, `512MB`, Go durations, ISO-8601), prefer them — then the value itself carries the unit and the parser enforces it.
- When consuming an existing unitless key, don't guess from the value's magnitude ("30 is probably seconds"). Read the code that uses it, then add a comment at the key documenting the unit you confirmed.
- Renaming an existing unitless key to a united one is a config key rename: alias the old name during transition, don't break environments to improve a name.

**Red flags that you're about to violate this:**
- "The unit is obvious from context."
- "The docs explain that it's milliseconds."
- "Everyone on the team knows timeouts are in seconds here."
- "Adding _ms makes the key name clunky."
- "The value 30000 makes it clear it's milliseconds."

### Read Config at Call Time, Not Import Time

NEVER read environment variables or config files in code that executes at module import — top-level statements, class-attribute defaults, decorator arguments, function parameter defaults. Import-time reads freeze a value before dotenv loading, test patching, or app bootstrap can run, and the resulting bugs depend on import order.

- Put config reads inside a function or a lazily-initialized config object: a `get_settings()` accessor, a cached factory, a config class instantiated during app startup — anything that executes after the environment is fully assembled.
- These are all import-time reads in disguise; avoid every one:
  - `TIMEOUT = int(os.environ["TIMEOUT"])` at module top level
  - `def fetch(url, timeout=settings.TIMEOUT)` — parameter defaults evaluate at definition time in many languages
  - `@retry(attempts=config.MAX_RETRIES)` — decorator args evaluate at import
  - class attributes initialized from `env` in the class body
- Caching is fine — read once at startup and reuse — as long as "once" happens inside the application's init path, not as a side effect of `import`.
- If the project already has a settings object or config accessor, route new values through it instead of adding fresh `os.environ` reads at module scope.
- In tests, the proof that you did this right: setting an env var before calling the function changes behavior, regardless of when the module was imported.

**Red flags that you're about to violate this:**
- "A module-level constant is cleaner than a function call."
- "This module is always imported after dotenv loads."
- "I'll read it once at the top so we don't pay the lookup cost."
- "The default parameter makes the signature self-documenting."
- "It works when I run this file directly."

### Reject Unknown Config Keys

Config loading must reject or loudly warn on keys it doesn't recognize. NEVER build or extend config handling that silently ignores unknown keys — a typo'd key that does nothing while the default runs is the most expensive kind of nothing.

`get(key, default)` handles the missing key. Nothing handles the unconsumed key unless you build it.

- Use strict parsing where the stack offers it: pydantic with `extra="forbid"`, serde's `deny_unknown_fields`, JSON Schema with `additionalProperties: false`, yaml/struct decoders in strict mode. If the project's config library has a strict switch, turn it on for config (APIs are a different question; config files have exactly one writer-audience and deserve strictness).
- If strictness isn't available, add the converse check: after loading, diff the file's keys against the known-key set and fail or warn-with-key-name on leftovers. One function, reusable, worth writing.
- Apply the same rigor to env vars where feasible: a documented prefix (`APP_*`) makes "set but unrecognized" detectable; warn on `APP_*` vars nothing consumed.
- Unknown-key errors should name the key and suggest the nearest valid one ("unknown key `max_conections`; did you mean `max_connections`?"). The error exists for a human mid-typo; serve them.
- When you remove or rename a key (with its alias window), keep the old name in the known-set as an explicit "deprecated, use X" rejection rather than letting it age into anonymous silence.
- When you *write* config, the same discipline inverted: copy key names from the schema or existing usage, never retype them.

**Red flags that you're about to violate this:**
- "Extra keys are harmless, the loader just skips them."
- "Strict mode might break someone's existing config file." (That file has a key doing nothing — that's the breakage, already shipped.)
- "Typos are rare and code review will catch them."
- "I'll just use .get() with a default like the rest of the file does."
- "Warning on unknown keys is too noisy."

### Respect the Config Precedence Order

NEVER improvise the precedence between config sources. The project has (or must get) ONE resolution order — typically CLI flag > env var > config file > default — and every key resolves through it identically.

A single key with reversed precedence creates an override that silently doesn't apply. Every layer looks correct in isolation; only the order is wrong, and nothing displays the order.

- Before adding any config read, find how existing keys resolve — the settings library, the config loader, the established `flag || env || file || default` chain — and route the new key through the same machinery. Not a lookalike chain you wrote at the call site: the same machinery.
- Never read `os.environ` / `process.env` directly from business logic when a config layer exists. Direct reads bypass file values, test overrides, and the precedence order all at once.
- If the project has no defined precedence (config is read ad hoc all over), don't add to the ad hoc pile — flag it, and at minimum make your addition's order match the most common existing pattern, stating which order you matched.
- Empty-vs-unset matters in layering: decide (and match the project's convention on) whether an empty env var overrides a file value or is treated as absent. Don't let `??` vs `||` make that decision for you.
- When debugging "I changed the config and nothing happened," check resolution order before anything else — and when you fix one of these, fix the order, don't just move the value to the winning layer.

**Red flags that you're about to violate this:**
- "I'll check the env var first since that's most specific." (Is that this project's order?)
- "Reading process.env directly here is simpler than threading config through."
- "It doesn't matter which wins, both sources will have the same value."
- "I'll write the fallback chain inline, it's only three sources."
- "The override isn't working, so I'll just edit the other file too."

### Ship Config Schema Changes to Every Environment

When you change the shape of configuration — new required keys, renamed structures, changed types or nesting — update EVERY environment's config in the same change. NEVER update only the environment you're testing against.

A schema change updated in one environment isn't partially done; it's a scheduled breakage for each environment you skipped, detonating one deploy at a time.

- Before changing config structure, enumerate every file that holds an instance of it: `config/*.yml` per environment, env templates, Helm/terraform values, compose files, CI workflow env blocks, test fixtures, seed/sample configs. Grep for an existing key to find them all.
- Apply the structural change to every instance, using each environment's appropriate values. Don't copy dev's values into prod's file just to satisfy the shape — if you don't know prod's correct value, mark it explicitly and call it out, loudly, in the change description.
- If some environment configs live outside this repo (an infra repo, a config service), you can't fix them here — so list them in the change description as required follow-ups, and prefer a backward-compatible reading (accept old and new shape during transition) so their deploys don't break in the meantime.
- New required keys deserve startup validation, so an un-updated environment fails its deploy immediately instead of running on a fallback.
- Update the schema's documentation (example file, README, validation code) in the same change.

**Red flags that you're about to violate this:**
- "Dev config is updated and the app runs, so the migration works."
- "I'll let the staging deploy surface anything I missed."
- "Production config is someone else's file to maintain."
- "The new key has a default, so the other environments don't need it explicitly."
- "Test fixtures aren't real config, they can keep the old shape."

### Single-Source Every Config Value

NEVER introduce a second definition of a config value that already exists somewhere in the project. Every value gets exactly one authoritative definition; everything else references it.

Duplicated config doesn't fail when you write it — it fails months later when someone updates one copy and the others silently keep the old value.

- Before hardcoding any URL, port, timeout, bucket name, or identifier, search the repo for it. If it exists in a config file, env template, or constants module, reference that definition instead of pasting the literal.
- If a value must appear in multiple artifacts that can't share code (e.g., app config and `docker-compose.yml`), make one the source of truth, derive or inject the others (env interpolation, build-time templating), and if true derivation is impossible, add a comment at every copy pointing to the authoritative one.
- When you find existing duplication while working, don't add to it. Flag it, and consolidate if it's in scope.
- New constants belong in the project's existing config layer, not in a fresh `constants.ts` next to the code that wants them.
- "Same value, different name" counts: `API_URL`, `BASE_API_ENDPOINT`, and `serviceUrl` holding identical strings are duplication wearing disguises.

**Red flags that you're about to violate this:**
- "It's just one string, defining it here is simpler than importing config."
- "The other copies are in different formats, so sharing isn't practical."
- "This value never changes anyway."
- "The test file needs its own copy so tests stay self-contained."
- "I'll paste it now and consolidate in a follow-up."

### Size Defaults for Production, Not the Demo

When choosing a default for any capacity, limit, or rate config, ALWAYS ask: what does this value do at production load, during a downstream outage, on the biggest tenant? The default is what production will run, because most deployments never override most keys.

"Works in dev" is the weakest possible evidence about a default — dev traffic can't punish a bad one.

- Anything that accumulates gets a bound by default: caches, queues, buffers, batch sizes, in-flight request counts. Unbounded is not a default; it's an outage with patience. If a bound feels arbitrary, a generous explicit bound still beats none.
- Anything that retries gets a cap and backoff by default: max attempts, max total time, jitter. Default-infinite retries are a self-inflicted DDoS waiting for a downstream blip.
- Anything that accepts input gets a size limit by default: request bodies, uploads, line lengths, array counts.
- Pools and concurrency sized for "my machine" are not defaults — if the right value depends on the deployment, make the key required (fail at startup when unset) instead of guessing small.
- Don't weaken an existing safety default to make dev pleasant. Loosen it in the dev overlay; the shared default stays production-safe.
- State your reasoning when you pick a default: "default 10MB body limit; raise per-environment if needed" is a decision someone can review. A bare number is not.

**Red flags that you're about to violate this:**
- "Unlimited is fine, the cache never gets big."
- "I tested it and memory usage was tiny."
- "Production will obviously override this."
- "A limit might break someone's legitimate use case, so no limit."
- "Four workers handled all my test load."
- "Retry forever — it should be resilient."

### Update .env.example With Every New Var

ALWAYS update `.env.example` (or the project's env template: `.env.sample`, `.env.dist`, `env.template`, config README) in the same change that introduces a new environment variable. A new env var read in code is an interface change; the example file is the interface declaration.

- When you add any read of a new env var (`process.env.X`, `os.environ["X"]`, `ENV["X"]`, `os.Getenv("X")`), add the same key to the example file in the same commit.
- Use a placeholder or safe example value, never a real one: `STRIPE_WEBHOOK_SECRET=whsec_xxx`, not a live secret. Add a one-line comment saying what it's for and whether it's required or optional.
- Keep ordering and grouping consistent with the existing file. Put the new var next to related ones, not at the bottom.
- If the project has multiple template files (e.g., `.env.example` and `docker-compose.yml` environment blocks, or a Helm values file), update every place that enumerates env vars. Search for an existing var name to find them all.
- If the project has no env template at all, say so and ask whether to create one — don't silently leave the new var undocumented.
- Removing or renaming a var follows the same rule: the example file changes in the same commit.

**Red flags that you're about to violate this:**
- "I set it in .env locally, so the app runs fine."
- "It's optional, so it doesn't really need to be in the example."
- ".env is gitignored, so env vars aren't part of the diff."
- "I'll add it to the docs later once the feature settles."
- "Whoever deploys this will know they need to set it."

### Validate Config at Startup, Not First Use

ALWAYS validate every config value — presence, type, format, range — during application startup, before the process reports healthy. NEVER let the first validation of a value be the moment a code path finally uses it.

Lazy validation moves the failure from deploy time (cheap, attributable, the author is watching) to first-use time (expensive, 3am, the author is asleep).

- Parse and validate all config in one pass at boot: URLs parse, ports are in range, enums match, durations are positive, referenced files exist. A failure here exits non-zero with a message naming the key and the problem.
- Validate values you can check without side effects eagerly and always. For values that imply a connection (database URL, broker address), at minimum validate the format at startup; verify connectivity in the readiness check.
- Rarely-used config gets the same treatment as hot-path config. The export job's bucket name is exactly the value lazy validation will miss, because "rarely used" means "first use is far from the deploy."
- When you add a new config value, add its validation to the startup pass in the same change — not a check at the call site.
- Don't catch-and-continue during the startup pass. A config error that's logged-and-ignored at boot is lazy validation with extra steps.
- If the project has no startup validation pass, creating one is worth proposing; bolting one more lazy check onto the pile is not.

**Red flags that you're about to violate this:**
- "I'll validate it where it's used, that keeps the logic together."
- "This config is only for the weekly job, no need to check it at boot."
- "The app shouldn't fail to start over an optional feature's config."
- "If the value is bad, the error when we use it will be clear enough."
- "Adding it to the startup validator means touching another module."
