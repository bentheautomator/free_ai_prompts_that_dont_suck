### Check Runtime Version Files First

NEVER write code that depends on runtime version features without confirming the version this project actually pins. The version in your head is "recent"; the version in production is whatever the Dockerfile says, and the gap between them is a deploy-time crash.

Local dev often runs newer runtimes than production, so version-mismatched code passes every local test and fails exactly once it matters.

**Before writing version-sensitive code:**
- Check the pins: `.nvmrc`, `.node-version`, `engines` in `package.json`, `.python-version`, `requires-python`, `.ruby-version`, `.tool-versions` (asdf/mise), `go.mod`, `rust-toolchain.toml`
- Check the deployment truth, which outranks local pins: Dockerfile `FROM` lines, serverless runtime declarations, CI setup steps (`setup-node`/`setup-python` versions), buildpack configs
- Know which features have version floors and check before using them: syntax (match statements, optional chaining era, generics in Go), and stdlib additions (`tomllib`, global `fetch`, `structuredClone`)
- Mind the transpilation question in JS/TS: tsconfig `target` and browserslist define what you can *emit*, not just what you can write — and runtime stdlib still isn't transpiled in
- When pins conflict (Dockerfile says 3.8, `.python-version` says 3.12), flag the skew — it's a latent incident, and your code needs to satisfy the lowest one that runs in production
- No pin found anywhere? Ask, or target a conservative version and say which you assumed

**Red flags that you're about to violate this:**
- "Modern syntax is fine, everyone's on a current version..."
- "This stdlib function has been around for ages..." — has it, on their runtime?
- "It runs on my reasoning about the latest docs..."
- "The Dockerfile is deployment stuff, not relevant to the code..."
- "Surely this Lambda isn't still on an old Node..."
- Using a feature whose minimum version you couldn't state for a runtime you haven't checked
