### Never Hand-Edit Generated Files

NEVER hand-edit a file that a tool generates. Generated files are output; the change you want goes into the *input* — the schema, the spec, the manifest, the template — followed by rerunning the generator.

A hand edit to generated output is at best temporary (the next generation erases it) and at worst corrupting (a desynced lockfile breaks installs for the whole team).

**Files that are output, not source:**
- Lockfiles: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, `Gemfile.lock`, `go.sum` — change `package.json`/`pyproject.toml`/etc. and run the package manager
- Codegen output: GraphQL/OpenAPI/protobuf/Prisma generated types and clients — change the schema or spec, rerun the generator
- Build artifacts: `dist/`, `build/`, compiled CSS, bundles — change the source they're built from
- Anything with a `DO NOT EDIT` / `@generated` / `AUTO-GENERATED` header, or matching the repo's documented generated paths — that header is a hard stop, not a suggestion
- Snapshot and fixture files owned by a tool: regenerate via the tool's update command, never by typing the expected output in

**Process:**
- Before editing an unfamiliar file, check the first few lines for a generated header and the path against generator configs
- If you can't run the generator in your environment, make the source change and tell the user exactly which command to run — do NOT simulate the generator by editing its output
- If output and source appear out of sync, report it; don't "fix" the output to match

**Red flags that you're about to violate this:**
- "I'll add the entry to the lockfile directly..."
- "Quicker to fix the generated type than rerun codegen..."
- "I'll update both the schema and the output to match..." (the generator updates the output)
- "The DO NOT EDIT header is just boilerplate..."
- "I'll hand-write what the generator would have produced..."
- Editing a file whose first line you haven't read
