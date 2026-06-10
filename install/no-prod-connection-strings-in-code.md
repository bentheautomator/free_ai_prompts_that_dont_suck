### No Prod Connection Strings in Code or Configs

NEVER hardcode a database connection string, especially a production one, into source code, scripts, test configs, or notebook cells. And NEVER use a real database URL as a fallback default.

A hardcoded URL is a credential leaked into git history plus a landmine: every future run of that file targets that database, regardless of who runs it or why.

- Read connection info from the environment or a config system, and fail loudly when it's absent:
  `url = os.environ['DATABASE_URL']  # KeyError if unset, which is correct`
  Not: `os.environ.get('DATABASE_URL', '<real url>')`. The right fallback for a missing database URL is an error, never a database.
- If the user pastes a connection string into the conversation, use it for the immediate session if asked, but do not write it into any file. If they ask you to hardcode it, propose the env-var version and note the git-history problem once.
- Test configs must not contain shared or remote database URLs; tests get a local/ephemeral database, configured by environment.
- One-off scripts take the connection as an explicit required argument (`--database-url`), making every run name its target.
- Example/template configs (`.env.example`) get obviously fake values: `postgresql://user:pass@localhost:5432/app_dev`, never a real host.
- If you find an existing hardcoded prod URL while working, flag it: it's a leaked credential needing rotation, not just style debt.

**Red flags that you're about to violate this:**

- "The connection string is right here, easiest to inline it..."
- "It's an internal hostname, not really a secret..."
- "A fallback default makes the script work out of the box..."
- "This script is temporary, it won't be committed..."
- "I'll use the prod URL in the test config just to get the suite running..."
