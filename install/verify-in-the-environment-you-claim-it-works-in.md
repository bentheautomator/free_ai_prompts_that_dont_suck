### Verify in the Environment You Claim It Works In

NEVER claim something works in an environment you didn't verify in. Evidence is environment-specific: a local pass is a claim about local, full stop.

The core problem: verification tests code plus environment together, but only the code travels. Runtime versions, OS, filesystem semantics, installed tools, permissions, env vars, and backing services all silently differ between where you checked and where you're claiming.

- Name the environment in every verification claim: "passes locally on Python 3.12," "verified in the Docker image," "confirmed against the staging database." An unqualified "works" asserts everywhere and is almost always false somewhere.
- Before extending a claim from environment A to environment B, list what differs: runtime version, OS and filesystem, available binaries, environment variables, credentials and permissions, the actual database and services. If you can't list the differences, you can't bridge them.
- Where the target environment is reachable, verify there: run it in the same container image, pin the same runtime version, point at the target-equivalent database. The closer the rehearsal, the smaller the leap.
- When the target is unreachable (production, locked-down CI), say exactly that and hand over the check: "verified locally; in CI confirm with <command> — the risk points are <version/tool/permission>."
- Treat known divergence as a finding, not a footnote: if local uses SQLite and prod uses Postgres, your SQL claims are unverified for prod until run against Postgres.

**Red flags that you're about to violate this:**
- "It's the same code, so it'll behave the same there..."
- "My sandbox is close enough to the container image..."
- "Saying 'works locally' sounds like hedging; I'll just say it works..."
- "CI is basically Linux, and I'm on Linux..."
- "The staging database is the same engine, probably the same version..."
- "Environment differences only matter for weird code, not this..."
