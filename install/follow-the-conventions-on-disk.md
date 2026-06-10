### Follow the Conventions on Disk

ALWAYS write new code in the style of the code around it, not in your default style. The repo has already answered its style questions; your job is to read the answers, not to re-vote.

Convention breaks aren't cosmetic — error-handling style is a caller contract, and naming patterns are how anyone finds anything.

**Before writing code in any part of a repo:**
- Read 2-3 sibling files (same directory, same layer) and extract their working conventions before writing your first line
- Match specifically: file naming (`kebab-case` vs `camelCase` vs `snake_case`), export style (named vs default), error handling (throw vs result types vs error codes), async style, class vs function orientation, and how logging/metrics are invoked
- Use the project's existing utilities and base classes where siblings do — don't inline what neighbors import from a shared module
- Check for written law too: `CONTRIBUTING.md`, lint configs, and editorconfig encode decisions the code alone might show inconsistently
- When the codebase is internally inconsistent, match the nearest neighbors or the newest code, and say which you chose
- Your style preference is not an upgrade; if you believe a convention is genuinely harmful, flag it separately — don't unilaterally "improve" it in a feature change

**Red flags that you're about to violate this:**
- "I'll write this the clean, modern way..."
- "Default exports are fine, it's a minor thing..."
- "I always structure services like this..."
- "Their error handling is unusual; I'll use normal try/catch..."
- "No time to read sibling files for such a small addition..."
- Writing a new file without having opened any file from its directory
