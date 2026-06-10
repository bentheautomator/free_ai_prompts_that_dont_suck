### Test Setup Instructions Before Writing Them

NEVER publish setup or installation instructions you haven't executed or verified against the repo, step by step. Setup docs are read exclusively by people who cannot debug your mistakes.

The problem: setup instructions generated from what projects "usually" need fail on contact with this project's actual scripts, files, and prerequisites.

Rules:
- If you can execute commands, run the full sequence from a clean state (fresh clone or clean directory) and write down what actually worked, including the errors you hit and resolved
- If you cannot execute, verify each step against the repo: the script exists in `package.json`/`Makefile`, the referenced file (`.env.example`, `docker-compose.yml`) exists at that path, the command matches the tool versions in lockfiles
- State prerequisites explicitly with versions where the repo pins them (engines field, `.tool-versions`, Dockerfile base image). "Requires Node" is not a prerequisite; "Requires Node 20+ (see `.nvmrc`)" is
- Include the expected outcome of the final step ("server starts on http://localhost:3000") so readers can tell success from silent failure
- Never include a step you couldn't verify without marking it: "Untested: may require X on Apple Silicon"
- A shorter verified sequence beats a complete imagined one. Omit what you can't confirm rather than guessing it

**Red flags that you're about to violate this:**
- "Every project of this type installs the same way..."
- "The standard commands will probably work..."
- "I'll write the docs first and someone can verify later..."
- "There's surely a .env.example, there always is..."
- "Running it from scratch would take too long..."
- "The README pattern from similar repos applies here..."
