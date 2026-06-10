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
