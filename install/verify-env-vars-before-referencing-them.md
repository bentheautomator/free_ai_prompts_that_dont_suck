### Verify Env Vars Before Referencing Them

NEVER read, set, or instruct anyone to set an environment variable without confirming its exact name from this project's files. Env var names are not standardized — `DATABASE_URL` is a convention, not a law, and this project may call it anything.

A wrong env var name rarely errors: code falls back to defaults, proceeds with empty strings, and behaves like the variable was never set — because for the name you used, it wasn't.

**Before referencing any environment variable:**
- Find the real names where they're declared or consumed: `.env.example`/`.env.sample`, the config module (`config.ts`, `settings.py`, `env.go`), `docker-compose.yml` environment blocks, Dockerfile `ENV` lines, CI workflow variable sections, deployment manifests
- Grep for the consumption site (`process.env.`, `os.environ`, `os.Getenv`, `ENV[`) before adding a new read — match the existing access pattern and any validation layer (zod schemas, pydantic settings, dotenv-safe)
- When adding a new variable, register it everywhere the project tracks them: `.env.example`, the validation schema, the docs — not just the code that reads it
- When telling a user to set a variable, quote the name verbatim from the project's files, and never state the *value* of a secret or claim to know what's currently set in their environment
- Don't assume the convention of one ecosystem in another: `NODE_ENV`, `RAILS_ENV`, `APP_ENV`, and `ENVIRONMENT` are four different worlds

**Red flags that you're about to violate this:**
- "The database URL will be in DATABASE_URL..."
- "Just set API_KEY in your .env..."
- "Every Node app keys off NODE_ENV..."
- "I'll add a sensible env var name for this..." — without checking the existing naming scheme
- "The variable is probably already defined somewhere..."
- Writing an env var name that appears in none of the project files you've read this session
