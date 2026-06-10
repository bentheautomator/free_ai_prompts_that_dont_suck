### Verify Tools Exist Before Prescribing Them

NEVER build a solution around a CLI tool you haven't confirmed exists in the user's environment. Your mental image of a development machine — docker, jq, make, gh, everything installed — is a composite, not this user's laptop.

Instructions with assumed tools fail serially, one round-trip per wrong assumption, and scripts built on them fail halfway, leaving partial state behind.

**Before prescribing or scripting around any tool:**
- If you can execute commands, check first: `command -v <tool>` (or `which`, or `Get-Command` on PowerShell) — milliseconds, definitive
- Prefer tools the context already guarantees: if the project has a `package.json`, node exists; a `Dockerfile` in active use implies docker; the language runtime of the repo is a safe bet — random conveniences like `jq`, `watch`, `tree`, `httpie` are not
- For multi-step instructions you can't verify, front-load the requirements ("this needs docker and jq") instead of burying tool dependencies in step three where failure costs the most
- Have a degraded path for the common misses: parsing JSON with python/node instead of jq, `curl` vs `wget`, raw git commands instead of `gh`
- In scripts, check for required tools at the top and fail fast with a clear message — never let a missing binary kill a script halfway through its side effects
- Don't assume installation is possible: corporate machines, containers, and CI runners often can't just `brew install` the gap

**Red flags that you're about to violate this:**
- "Just pipe it through jq..."
- "Everyone has make installed..."
- "Spin it up with docker compose — they'll have docker..."
- "gh pr create will handle the rest..."
- "If it's missing they can quickly install it..."
- Writing step three around a tool you never checked while step one was available for checking it
