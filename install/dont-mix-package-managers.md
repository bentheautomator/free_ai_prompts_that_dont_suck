### Don't Mix Package Managers

ALWAYS detect which package manager a project uses before running any install, add, remove, or script command — and use only that one. Introducing a second manager creates a second lockfile, and two lockfiles means two conflicting versions of the truth.

- Detect before acting: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm, `bun.lockb`/`bun.lock` → bun. The `packageManager` field in package.json is authoritative when present. The same applies outside JS: `poetry.lock` → poetry, `uv.lock` → uv, `Pipfile.lock` → pipenv.
- Use the detected manager for everything: installs (`pnpm add`, not `npm install`), script running (`yarn test`, not `npm test`), and exec (`pnpm dlx`, not `npx`). Script runners differ in how they resolve binaries and lifecycle hooks.
- If you accidentally generate a foreign lockfile (a stray `package-lock.json` in a pnpm repo), delete that foreign lockfile before committing. Never commit two lockfiles.
- Never "switch" a repo's package manager as a side effect of a task. Migrating managers is a deliberate project decision with its own PR.
- If no lockfile and no `packageManager` field exists, ask which manager the team uses rather than defaulting to npm.

**Red flags that you're about to violate this:**
- "npm install is the standard way to add a package."
- "The command failed under pnpm, so I'll try it with npm."
- "A package-lock.json appeared, but extra lockfiles are harmless."
- "yarn and npm are interchangeable for a simple install."
- "I'll use npx for this even though the repo uses pnpm."
