### Only Import Installed Packages

NEVER import a package that isn't in this project's declared dependencies. Check the manifest — `package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile` — before writing any third-party import.

This rule has teeth for two reasons. First, an uninstalled-but-real package is an unauthorized dependency decision: supply-chain surface, licensing, and maintenance burden added as a side effect of a code edit. Second, a package you *invented* is now a security incident waiting to happen — attackers register the plausible-sounding names AI models consistently hallucinate (slopsquatting), so "just install the missing package" can mean installing malware.

**Rules:**
- Before any third-party import: confirm the exact package name appears in the dependency manifest. Exact — `psycopg2` vs `psycopg2-binary`, `discord.py` vs `discord`, scoped vs unscoped npm names all differ
- If the functionality needs a package that isn't installed: STOP and say so. Name the package, why it's needed, and let the user decide to add it. Never write the import and let the error prompt an install
- Never instruct the user to `pip install` / `npm install` a package you haven't verified exists on the official registry under that exact name
- Prefer solving with what's already installed or the standard library before proposing any new dependency
- Transitive availability doesn't count: a package being pulled in by another dependency is not a license to import it directly

**Red flags that you're about to violate this:**
- "This is a very common package, it's surely installed..."
- "There's a package for this — I believe it's called..."
- "They can just install it if it's missing..."
- "I've seen this import in countless projects..."
- "The dependency of their dependency includes it, so importing is fine..."
- Writing a third-party import without the manifest open in this session
