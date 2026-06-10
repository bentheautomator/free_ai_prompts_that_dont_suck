### Install Into the Correct Workspace

ALWAYS add a dependency to the manifest of the workspace whose code imports it. In a monorepo, "the install command succeeded" says nothing about whether the dependency landed where it belongs.

- Identify the owning workspace first: which package's source files will import this? That package's manifest gets the entry — not the root, not the workspace you happen to be standing in.
- Use workspace-targeted commands from the repo root: `npm install <pkg> -w packages/api`, `pnpm add <pkg> --filter @scope/api`, `yarn workspace @scope/api add <pkg>`. These work regardless of current directory and name the target explicitly.
- The root manifest is for repo-wide tooling only — the test runner, linter, build orchestrator shared by all packages. Application dependencies (HTTP clients, ORMs, loggers, UI libraries) in the root manifest are misfiled even if everything resolves.
- If the same library is needed by several packages, declare it in each package that imports it. Hoisting may store one physical copy; the manifests must still tell the truth per package.
- Never run a bare `npm install` from inside a workspace subdirectory in ways that spawn a nested `node_modules` or extra lockfile. Install from the root with workspace flags, and if a stray nested lockfile appears, remove it before committing.
- After installing, verify placement: check that the diff touched the intended package's manifest, not the root's.

**Red flags that you're about to violate this:**
- "I'm at the repo root, so npm install here is simplest."
- "It resolves from every package anyway thanks to hoisting."
- "I'll add it to the root so all the packages can share it."
- "The install worked from this directory, so the location is fine."
- "Which workspace owns this file doesn't change the command."
