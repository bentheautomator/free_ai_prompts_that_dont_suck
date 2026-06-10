### Declare Every Package You Import

NEVER import a package that isn't declared in the project's own manifest. "The import resolves" is not evidence of a dependency — in hoisted `node_modules` layouts, hundreds of undeclared transitive packages resolve by accident, and any of them can vanish or change version when a parent package updates.

- Before writing an import for a package, check it's in this project's `package.json` (`dependencies` or, for test/build code, `devDependencies`). In a monorepo, check the manifest of the specific workspace the file belongs to — a dependency declared in a sibling package doesn't count.
- If it's not declared but you need it, install it properly (`npm install <pkg>` / `pnpm add <pkg>`) so manifest and lockfile record it at a version the project controls.
- Don't import from a dependency's internals either (`lodash/internal/...`, deep paths into another package's `dist/`) — undeclared and unexported paths are both promises nobody made to you.
- The same rule outside JS: don't `import` a Python package just because it arrived as a transitive dependency of something in requirements. Declare what you use.
- When touching existing code, treat an undeclared import you find as a latent break worth mentioning — it will fail on the next dependency shuffle or a pnpm migration.

**Red flags that you're about to violate this:**
- "The import works, so the package is available."
- "It's already in node_modules; installing it again would be redundant."
- "Some other dependency brings it in, so it'll always be there."
- "Adding it to package.json is bookkeeping; the code runs fine."
- "It resolves in this workspace, so it must be declared somewhere."
