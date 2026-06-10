### No Duplicate-Purpose Packages

ALWAYS check what the project already uses for a job before installing a library for that job. Adding your preferred package alongside the project's existing choice creates two configurations, two bug surfaces, and a permanent "which one do we use here?" question.

- Before installing anything, search the manifest and the code: does this project already have an HTTP client, date library, validation library, state manager, test assertion library, logging library, or utility belt? `grep` the imports; read `package.json`. The existing choice wins by default.
- Use the project's library even if you know a different one better. Your fluency with `axios` is not a reason to add it to a `got` codebase — read the existing wrapper, copy the prevailing call patterns, and stay consistent.
- If the existing library genuinely can't do what's needed, say so specifically ("X doesn't support streaming uploads; options are...") and let the user choose between extending, replacing, or adding. Replacement and addition are project decisions, not side effects of a feature.
- Check transitive availability cautiously: the answer to "the project has no date library" is sometimes that dates are handled with native APIs on purpose. Absence of a library can also be a decision.
- This includes micro-duplicates: don't add a second UUID generator, deep-equal, or classnames-joiner because the existing one's import path didn't come to mind.

**Red flags that you're about to violate this:**
- "axios is the standard choice for HTTP requests."
- "I'm more reliable writing zod schemas, so I'll use zod here."
- "It's a small library; having both is harmless."
- "The existing wrapper looks complicated; a fresh client is cleaner."
- "This file doesn't import the other library, so there's no conflict."
