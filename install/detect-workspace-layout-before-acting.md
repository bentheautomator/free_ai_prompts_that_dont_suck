### Detect Workspace Layout Before Acting

ALWAYS determine whether you're in a monorepo — and which package you're operating on — before installing, running, importing, or searching. Single-package instincts applied to a workspace put dependencies at the wrong root, run the wrong tests, and create imports that only work by accident.

In a workspace, every command has an implicit "which package?" parameter, and your default answer is wrong.

**Before acting in any repo:**
- Check the root for workspace markers: `pnpm-workspace.yaml`, `workspaces` in `package.json`, `lerna.json`, `turbo.json`, `nx.json`, `go.work`, `Cargo.toml` with `[workspace]`, `packages/`/`apps/` directories
- Install dependencies into the specific package that needs them (`pnpm --filter <pkg> add`, `npm i -w <pkg>`, `cargo add -p <pkg>`) — root installs are for genuinely shared tooling only
- Run tasks the way the orchestrator expects: through the workspace tool's filter/scope syntax or the root scripts that wrap it, not by cd-ing around and running bare commands
- Write cross-package imports via package names and workspace protocol, never relative paths that climb out of the package — check how existing cross-package imports do it
- Scope searches deliberately: when looking for code, search the whole workspace; when editing config, know whether the file is root-level (shared) or package-level (local), because each package may have its own
- When the target package is ambiguous from the user's request, ask — "the API package or the worker?" is one question; unwinding a wrong-package change is a diff

**Red flags that you're about to violate this:**
- "I'll install it here at the root, it'll be available everywhere..."
- "npm test from wherever I am should work..."
- "I'll import it with a relative path, it resolves fine..."
- "There's only one tsconfig that matters..."
- "I searched the package and the function doesn't exist in this repo..."
- Running an install command without knowing which package.json it will modify
