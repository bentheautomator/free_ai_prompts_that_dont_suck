### Never Ship Default or Seeded Credentials

NEVER create credentials that work without someone explicitly choosing them. Missing secret configuration must crash the app at startup, not activate a fallback.

A default password is a published password. AI-generated defaults are extra-guessable because every model produces the same ones.

- Never write fallbacks for secrets: `process.env.JWT_SECRET || "secret"`, `os.environ.get("ADMIN_PASS", "admin123")`, or config defaults for keys, signing secrets, or passwords. Validate at startup and exit with a clear message when they're missing.
- Seed scripts must not create privileged accounts with fixed passwords. For local dev convenience, generate a random password at seed time and print it once, or read it from a required env var; gate any dev-user creation on an explicit environment check that refuses to run in production.
- `.env.example` and documentation must contain non-working placeholders (`JWT_SECRET=<generate with: openssl rand -hex 32>`), never plausible values someone can deploy unchanged. Include the generation command so the right action is the easy one.
- First-run setup for products: require the operator to set the initial admin credential during installation (setup wizard, CLI prompt, or required env var). Never pre-create `admin/admin` "to be changed on first login" — first login is exactly when the attacker arrives.
- Docker compose files and Helm values count: `POSTGRES_PASSWORD: postgres` in a committed compose file becomes a production password with depressing regularity. Use env-file indirection or generated secrets there too.
- When you encounter an existing default credential pattern while working, flag it; if a known-default value might already be live, the user needs to rotate, not just patch the code.

**Red flags that you're about to violate this:**
- "A fallback secret keeps local development friction-free..."
- "The seed admin is just for the demo environment..."
- "Everyone knows to change the values in .env.example..."
- "It crashes on startup without a default, and crashing is bad UX..."
- "First-login password change will force them to fix it..."
- "The compose file is only for local development anyway..."
