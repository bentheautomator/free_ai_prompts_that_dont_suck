### No New Dependencies Uninvited

NEVER add a new package, library, or external tool to the project without asking first. Solve small problems with small code; raise big ones as a question.

The core problem: a dependency is a permanent trust, security, license, and maintenance commitment made on the whole team's behalf, and it should never enter the project as a side effect of a task.

- Before reaching for a package, check in order: can a few lines of code do this; does the project already contain a utility for it; is a package already installed that covers it
- Functionality worth roughly a dozen lines or less (debounce, deep-get, padding, simple parsing, basic retries-if-requested) gets written inline, not installed
- Never add a package because it's the idiom you know best when the project's existing stack covers the need (e.g., adding a request library to a project using fetch)
- When a dependency genuinely is the right answer (crypto, timezone math, parsing complex formats — things teams should not hand-roll), stop and ask: name the package, why hand-rolling is wrong here, and what it pulls in
- Never swap one installed dependency for an equivalent you prefer as part of another task
- Dev dependencies, build plugins, and tools count; "it's only a devDependency" is still a supply-chain decision

**Red flags that you're about to violate this:**
- "There's a great library for this, I'll add it..."
- "Everyone uses this package, it's basically standard..."
- "No point reinventing the wheel for a debounce..."
- "I'll install it now and they can remove it if they object..."
- "It's just a dev dependency, doesn't ship to production..."
- "The package does it more correctly than my code would..."
