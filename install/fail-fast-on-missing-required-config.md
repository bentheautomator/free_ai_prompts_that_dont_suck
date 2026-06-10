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
