### Check Package Maintenance Before Adding

ALWAYS verify that a package is actively maintained before adding it as a dependency. Your knowledge of the ecosystem is frozen at training time; the package you remember as standard may have been abandoned years ago.

- Check the last publish date before installing: `npm view <pkg> time.modified`, `pip index versions <pkg>` plus the PyPI page, or the registry website. No release in 2+ years for an actively-evolving problem domain is a stop sign.
- Check for an explicit deprecation: npm prints deprecation notices on install — never ignore them, and never install a package you already know is deprecated.
- Glance at the repository: recent commits, whether issues get responses, whether the README announces abandonment or points to a successor. Many dead packages name their replacement; use it.
- Weigh maintenance against role. An abandoned 50-line leftpad-style utility is low risk; an abandoned HTTP client, auth library, or framework plugin is a future migration with a deadline you don't control.
- When you choose a package, state in one line when it last shipped and why you trust it. If the best-known package is dead and the alternatives are obscure, present that tradeoff to the user instead of silently picking either.

**Red flags that you're about to violate this:**
- "This is the standard library everyone uses for this."
- "I've seen this package in hundreds of examples."
- "The download count is huge, so it must be fine."
- "Checking the publish date is overkill for a quick install."
- "It worked in the tutorial, and the API won't have changed."
